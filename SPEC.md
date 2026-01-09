# ITサポートチャットシステム 統合要件定義書 (Robust Draft & Review Model)

## 1. システム概要
社内の問い合わせ窓口(Chat A)と連携する、サポート担当者向け管理システム(Chat B)。
**「誤爆の完全防止」**と**「サポート品質の均一化」**を最優先事項とし、Core/Adapterアーキテクチャによるプラットフォーム非依存性と、厳格なステートマシンによる安全性を担保する。

### アーキテクチャ方針 (Core vs Adapter)
* **Core (Chat B Backend):**
    * チケット管理、メッセージ保存、ドラフト→チェック→公開のステートマシン、権限管理、重複排除ロジックを集約。
    * 特定のチャットツールに依存しない共通データモデルを持つ。
* **Adapter (Gateway):**
    * Chat A (Slack/Teams/Line等) との通信を抽象化する層。
    * 責務: `listenIncoming()` (正規化してCoreへ渡す), `sendOutbound()` (Coreからの指示をAPIへ投げる)。

---

## 2. 画面レイアウトと役割 (3ペイン構成)

### Pane 1: Ticket Inbox (左)
* **役割:** 未解決案件の管理。
* **表示対象:** ステータスが `Open` のチケット一覧。
* **表示項目:** ユーザー情報、件名、経過時間(`lastPublicAt`基準)、担当者アイコン(`assignees`)、**ドラフト状態バッジ**。

### Pane 2: Public Timeline (中央 / Main)
* **役割:** 「確定した対話履歴」の閲覧。
* **Source of Truth:** **Chat Bのデータベース (Core Store) を正とする。**
    * Chat AのAPIから毎回履歴を引くのではなく、Coreに保存された `visibility: public` のログを表示する。
    * これにより、Chat A側の仕様変更やレート制限の影響を受けず、高速な表示を担保する。
* **入力制限:** **完全に入力不可。** 閲覧専用コンポーネントとして配置する。

### Pane 3: Workspace & Internal Chat (右 / Sub)
* **役割:** チーム相談、回答案の起案(Draft)、AIレビュー、承認・公開操作。
* **デザイン:** 背景色（例: 薄黄色）による視覚的なゾーニング。
* **機能:**
    * **Internal Note:** チーム内連絡用チャット。
    * **Draft Editor:** 回答案作成エディタ。
    * **Review Panel:** AI/人間による指摘事項の表示。

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
    "platform": "slack",
    "dmId": "C12345678",          // 送信先チャンネル/DM ID
    "lastInboundCursor": "ts_001" // Webhook取りこぼし復旧用カーソル
  },

  // 運用管理データ
  "assignees": ["admin_05"],      // 担当者ID配列
  "lastPublicAt": "2025-01-09T10:00:00Z", // 最終回答日時 (SLA監視用)
  "lockVersion": 1,               // 楽観ロック用バージョン
  
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
  "replyToMessageId": "msg_1990", // スレッド整合用

  // 制御フラグ
  "visibility": "internal",     // "public" (Pane2) | "internal" (Pane3)
  "origin": "console",          // "chatA"(ユーザー) | "console"(担当者) | "system"(Bot)
  
  // ドラフト管理 (visibility: internal の場合のみ有効)
  "isDraft": true,
  "draftStatus": "checked",     // pending | checking | checked | published
  "aiCheckResult": {
    "passed": true,
    "warnings": []
  },

  // 冪等性管理
  "idempotencyKey": "uuid_v4_generated_by_client",
  "publishedAt": null,          // 公開された時刻

  "senderId": "admin_05",
  "timestamp": "2025-01-09T10:10:00Z"
}
````

---

## 4. 業務ワークフロー (Draft -> Check -> Publish)

APIをリソース操作型に整理し、状態遷移を明確化する。

### Step 1: 起案 (Drafting)
担当者は「社内メモ」か「回答案」かを選択して投稿する。

* **社内メモ:** `POST /api/tickets/{id}/notes`
    * `visibility: internal`, `isDraft: false` で保存。チーム内共有のみ。
* **回答案:** `POST /api/tickets/{id}/drafts`
    * `visibility: internal`, `isDraft: true` で保存。
    * 保存後、自動的にチェックプロセスへ移行。

### Step 2: チェック (Checking)
Bot/AIが回答案を監査する。

* **自動チェック:** `draftStatus: checking` → `checked` / `rejected`
* **修正:** 修正が必要な場合、`PUT /api/tickets/{id}/drafts/{msgId}` で内容更新。
* **再審査:** `POST /api/tickets/{id}/drafts/{msgId}/recheck` でAIチェックを再実行。

### Step 3: 公開 (Publishing)
担当者が「Publish」を実行する。**この操作は「メッセージ送信」ではなく「ドラフトの状態遷移」として扱う。**

* **Action:** `POST /api/tickets/{id}/drafts/{msgId}/publish`
* **Payload:**
    ````json
    { "idempotencyKey": "gen_uuid_v4..." }
    ````
* **System Logic:**
    1.  **Server Guard:** `draftStatus` が `checked` であることを検証（クライアントバイパス防止）。
    2.  **Idempotency Check:** 既に `publishedAt` がある、またはキーが重複している場合は成功応答を返すが処理はスキップ。
    3.  **Adapter Publish:** Adapter経由で Chat A へ送信。
    4.  **State Update:**
        * DBの `visibility` を `public` に更新（または `public` レコードを複製作成し、Draftは済みステータスへ）。
        * `publishedAt` を打刻。
    5.  **Notify:** WebSocketで Pane 2 (Timeline) に新着通知。

---

## 5. 堅牢性・安全性要件 (Fail-safe & Reliability)

### 5.1 Publishの冪等性 (Idempotency)
* **要件:** ネットワーク遅延や連打により `publish` APIが複数回呼ばれても、**Chat Aへの送信は必ず1回のみ**であることを保証する。
* **実装:**
    * `Publish` リクエストには必ずクライアント生成の `idempotencyKey` を含める。
    * DBのユニーク制約、またはRedisによるロックを用いて重複実行をブロックする。

### 5.2 無限ループ（反射）防止
* **要件:** Chat Bが送信したメッセージを、Adapterが「ユーザーからの新着」として誤検知し、再び取り込む「無限ループ」を防ぐ。
* **実装:**
    * **Origin Check:** AdapterはWebhook受信時、SenderIDがBot自身であれば破棄する。
    * **Signature:** 可能であれば送信メッセージのメタデータに `source: console` を付与し、受信時にフィルタリングする。

### 5.3 サーバーサイド・ガード
* **要件:** UI上のボタン無効化だけでなく、APIレベルで不正な遷移を拒否する。
* **実装:**
    * `publish` エンドポイントは、対象メッセージの `draftStatus` が `checked` (AI/承認済み) でなければ `400 Bad Request` を返す。
    * Ticket作成時に確定した `chatA.dmId` (宛先) は、後から変更不可とする（宛先改ざん防止）。

### 5.4 添付ファイルの取り扱い
* **方針:** ファイルの実体はコピーせず、可能な限り「リンク共有」とする。
* **セキュリティ:**
    * Chat Bからアップロードされたファイルは、署名付きURL (Presigned URL) で提供し、有効期限を設ける。
    * Chat Aへの送信時は、そのURLを展開して送信する。

---

## 6. API インターフェース一覧

### Ticket Operations
* `GET /api/tickets?status=open`: Inbox取得
* `GET /api/tickets/{id}`: 詳細・メタデータ取得

### Timeline (Pane 2)
* `GET /api/tickets/{id}/timeline`:
    * `visibility: public` のメッセージのみを時系列順に返す。
    * Source of Truth は Chat B DB。

### Workspace (Pane 3)
* `GET /api/tickets/{id}/items`:
    * `visibility: internal` (Note + Draft) および `public` の全量を時系列で返す。
* `POST /api/tickets/{id}/notes`: 社内メモ作成。
* `POST /api/tickets/{id}/drafts`: 回答案(Draft)作成。
* `PUT /api/tickets/{id}/drafts/{msgId}`: 回答案修正。
* `POST /api/tickets/{id}/drafts/{msgId}/recheck`: AI再チェック。
* `POST /api/tickets/{id}/drafts/{msgId}/publish`: **公開実行 (状態遷移)**。

### Pane 3 UI設定例 (Deep Chat)
````javascript
// Deep Chat Config for Pane 3
const pane3Config = {
  style: { backgroundColor: '#fffbe6' }, // 警戒色
  textInput: {
    placeholder: '社内メモまたは回答案を入力...',
    styles: { container: { backgroundColor: '#fffbe6' } }
  },
  // 送信ボタンの挙動はカスタムイベントで制御
  html: '<button onclick="submitDraft()">回答案を作成</button>' 
};
````
