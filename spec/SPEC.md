# ITサポートチャットシステム 統合要件定義書 (Robust Draft & Review Model)

## 0. 仕様の読み方 (MVP / To‑Be)
本仕様は **現状(MVP)** と **To‑Be(完全形)** を併記する。
- **現状(MVP)**: 既存実装/運用に合わせた最低限の仕様。
- **To‑Be**: 誤爆防止・品質均一化・監査性を満たす最終形。

---

## 1. システム概要
社内の問い合わせ窓口(Chat A: direct4b)と連携する、サポート担当者向け管理システム(Chat B)。
**「誤爆の完全防止」**と**「サポート品質の均一化」**を最優先事項とし、Core/Adapterアーキテクチャによるプラットフォーム非依存性と、厳格なステートマシンによる安全性を担保する。

### アーキテクチャ方針 (Core vs Adapter)
- **Core (Chat B Backend)**
  - チケット管理、メッセージ保存、ドラフト→チェック→公開のステートマシン、権限管理、重複排除ロジックを集約。
  - 特定のチャットツールに依存しない共通データモデルを持つ。
- **Adapter (Gateway)**
  - Chat A (direct4b を主対象、将来Slack/Teams/Line等も視野) との通信を抽象化。
  - 責務: `listenIncoming()` (正規化してCoreへ渡す), `sendOutbound()` (Coreからの指示をAPIへ投げる)。

### direct4b Adapter 最小接続設計 (MVP)
- **利用SDK:** `f4ah6o/direct_sdk.mbt`
- **必須設定:** `api_token`, `bot_user_id`, `platform_name`
- **接続ライフサイクル:** `connect` → `listen_incoming` 登録 → `send_outbound`
- **ループ防止:** `bot_user_id` と `is_bot` 判定で自己送信を破棄
- **メッセージ正規化:** direct4b 受信を `NormalizedMessage` に変換し、Coreへ渡す

---

## 2. 画面レイアウトと役割 (3ペイン構成 / HTMX+TMPX)
**UIはHTMXを中心に、TMPXでHTMLを生成する。**
言語をMoonBitに統一し、Server‑Side Rendering + HTMX partial更新で実装する。

### Pane 1: Ticket Inbox (左)
- **役割:** 未解決案件の管理。
- **表示対象:** `status: open` のチケット一覧。
- **表示項目:** ユーザー情報、件名、経過時間(`lastPublicAt`基準)、担当者アイコン(`assignees`)、**ドラフト状態バッジ**。

### Pane 2: Public Timeline (中央 / Main)
- **役割:** 「確定した対話履歴」の閲覧・公開操作。
- **Source of Truth:** **Chat Bのデータベース (Core Store) を正とする。**
  - Chat AのAPIから毎回履歴を引かない。
  - Coreに保存された `visibility: public` のログを表示する。
- **誤爆防止:**
  - **現状(MVP):** 公開返信フォームが存在するが、To‑Be では「直接送信」ではなく「安全な公開操作」に統合する。
  - **To‑Be:** Draft → Check → Publish の手順を経たものだけが公開可能。

### Pane 3: Workspace & Internal Chat (右 / Sub)
- **役割:** チーム相談、回答案の起案(Draft)、AIレビュー、承認・公開操作。
- **デザイン:** 背景色（例: 薄黄色）による視覚的なゾーニング。
- **機能:**
  - **Internal Note:** チーム内連絡用チャット。
  - **Draft Editor:** 回答案作成エディタ。
  - **Review Panel:** AI/人間による指摘事項の表示。

---

## 3. データモデル (JSON Schema)
### 3.1 Ticket (Session)
同時編集競合の防止（楽観ロック）と、外部プラットフォームとの紐付け情報を強化。

````json
{
  "ticketId": "tkt_001",
  "status": "open",       // "open" | "closed" | "pending"
  "subject": "VPN接続エラー",

  // 外部連携メタデータ (Adapter用)
  "chatA": {
    "platform": "direct4b",
    "dmId": "C12345678",
    "lastInboundCursor": "ts_001"
  },

  // 運用管理データ
  "assignees": ["admin_05"],
  "lastPublicAt": "2025-01-09T10:00:00Z",
  "lockVersion": 1,

  "createdAt": "2025-01-09T10:00:00Z",
  "updatedAt": "2025-01-09T10:05:00Z"
}
````

### 3.2 Message
`type` を廃止し、可視範囲(`visibility`)と発生源(`origin`)で厳密に管理する。

````json
{
  "messageId": "msg_2000",
  "ticketId": "tkt_001",

  // コンテンツ
  "text": "再起動をお試しいただけますか？",
  "attachments": [
    { "type": "image", "url": "https://...", "name": "screenshot.png" }
  ],
  "replyToMessageId": "msg_1990",

  // 制御フラグ
  "visibility": "internal",     // "public" | "internal"
  "origin": "console",          // "chatA" | "console" | "system"

  // ドラフト管理 (visibility: internal の場合のみ有効)
  "isDraft": true,
  "draftStatus": "checked",     // pending | checking | checked | rejected | published
  "aiCheckResult": {
    "passed": true,
    "warnings": [],
    "suggestions": []
  },

  // 冪等性管理
  "idempotencyKey": "uuid_v4_generated_by_client",
  "publishedAt": null,

  "senderId": "admin_05",
  "timestamp": "2025-01-09T10:10:00Z"
}
````

---

## 4. 業務ワークフロー (Draft → Check → Publish)

### Step 1: 起案 (Drafting)
担当者は「社内メモ」か「回答案」かを選択して投稿する。

- **社内メモ:** `POST /api/tickets/{id}/notes`
  - `visibility: internal`, `isDraft: false` で保存。
- **回答案:** `POST /api/tickets/{id}/drafts`
  - `visibility: internal`, `isDraft: true` で保存。

### Step 2: チェック (Checking)
- **現状(MVP):** Draft作成時は `Pending` のまま。`recheck` で `Checking` に遷移。
- **To‑Be:** Draft作成後に **自動でAIチェックが開始** され `Checking` に遷移。
- **仕様:** 自動チェックの **フック/インターフェースは必須**。実装は段階導入。

### Step 3: 公開 (Publishing)
担当者が「Publish」を実行する。**「送信」ではなく「ドラフトの状態遷移」** として扱う。

- **Action:** `POST /api/tickets/{id}/drafts/{msgId}/publish`
- **Payload:**
  ````json
  { "idempotencyKey": "gen_uuid_v4..." }
  ````
- **System Logic:**
  1. **Server Guard:** `draftStatus` が `checked` であることを検証。
  2. **Idempotency:** `idempotencyKey` は必須。
     - **同じキーなら 200/201 で同じ結果を返す。**
     - キーが無い場合は **400**。
  3. **Adapter Publish:** Adapter経由で Chat A へ送信（To‑Be必須 / MVPは未実装）。
  4. **State Update:** 同一レコードを `visibility: public` に更新。
  5. **Notify:** WebSocketで Pane 2 に新着通知。

---

## 5. 堅牢性・安全性要件 (Fail‑safe & Reliability)

### 5.1 Publishの冪等性
- `publish` は **idempotencyKey必須**。
- 同一キーは **同じ結果を返して処理をスキップ**。

### 5.2 無限ループ（反射）防止
- AdapterはWebhook受信時に **Bot自身の送信を破棄**。
- 送信メッセージに `source: console` などのメタデータを付与し、受信時にフィルタリング。

### 5.3 サーバーサイド・ガード
- UI無効化だけでなく APIレベルで不正遷移を拒否する。
- `publish` は `checked` 以外を **400 Bad Request**。
- Ticket作成時の `chatA.dmId` は変更不可。

---

## 6. 添付ファイルの取り扱い (Attachment Storage)
ユーザーは添付ファイルを送るため、Airlock側で **外部ストレージに自動保存** する。

- **方針:** AttachmentStorage を抽象化し、Box/kintone/S3等のドライバを差し替え可能にする。
- **優先順位:** Box > kintone > others。
- **基本運用:** **受信時に即保存** してリンク化する。
- **UI/送信:** 保存先の署名URLを利用して閲覧・送信。

---

## 7. API / HTMX インターフェース
**HTMXを主軸に、HTMLレスポンスをハイパーメディアとして扱う。**
JSON API は To‑Be または機械連携用として段階導入する。

### 7.1 HTML (HTMX) エンドポイント (MVP)
- `GET /` : 3ペイン画面
- `GET /partials/ticket/{id}` : 中央+右ペインの差分
- `POST /tickets/{id}/reply` : 公開返信 (MVPのみ)
- `POST /tickets/{id}/notes` : 内部メモ

### 7.2 JSON API (To‑Be)
- `GET /api/tickets?status=open`
- `GET /api/tickets/{id}`
- `GET /api/tickets/{id}/timeline`
- `GET /api/tickets/{id}/items`
- `POST /api/tickets/{id}/notes`
- `POST /api/tickets/{id}/drafts`
- `PUT /api/tickets/{id}/drafts/{msgId}`
- `POST /api/tickets/{id}/drafts/{msgId}/recheck`
- `POST /api/tickets/{id}/drafts/{msgId}/publish`

**レスポンス方針:** Ticket/Message は **全フィールドを返す** (chatA/assignees/lastPublicAt/attachments/replyToMessageId/idempotencyKey 等を省略しない)。  
**replyToMessageId:** 保存は必須、UIは将来対応。  
**HATEOAS方針:** HTMXのフォーム/リンクをサーバーが返すHTMLに集約する (JSONの `_links` は任意)。

---

## 8. ログ/外部化
- **監査ログ:** DuckDB に保存。
- **外部化:** 必要に応じて Parquet に書き出し、再ロード可能にする。

---

## 9. データストア
- **現状(MVP):** インメモリ。
- **To‑Be:** PostgreSQL / DuckDB のどちらも選択可能。
