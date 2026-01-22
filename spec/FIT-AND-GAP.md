- 方向性: 現状のコードに合わせて ./spec を更新するのが目的ですか？それとも ./spec を正としてコードを後追いで直す前提ですか？
    * 両方です。
- UI全体: src/web/layout.mbt はHTMX+TMPXの簡易3ペインですが、spec/SPEC.md は Deep Chat + Luna 前提です。SPEC.md を現状UIに合わせて簡略化しますか？それとも仕様どおり（Deep Chat/Luna）に戻しますか？
    * Deep Chat/LunaはOmitです。
    * TMPXでHTMXを書くことでコードを全てMoonBitに寄せることができます。言語の統一のメリットは大きいよね。
- Pane2: 仕様は「閲覧専用・入力不可」なのに、src/web/layout.mbt は公開返信フォームを表示しています。Pane2は本当に入力禁止で確定ですか？
    * 違います。誤って投稿しないようにする仕組みが欲しいのです。
    * ITサポート担当者は複数いる想定で、担当者間のディスカッションの後、確定した内容をユーザーに回答します。
- Pane3: 仕様は「Internal Note + Draft Editor + Review Panel」ですが、現状はノートのみです。仕様を簡略化（ノートのみ）に合わせますか？それともコード側の不足として仕様は維持しますか？
    * コード側の不足です。
    * 回答に至るまでの記録を残しておきたいです。多くは情報源のURLと担当者間のチャットになると思います。
- Draft作成: 仕様は「Draft作成後に自動でAIチェック開始」。現実装は draft_status=Pending のままです。仕様を「手動 recheck」に合わせて変更しますか？
    * よくわからないので言い換えてまた質問してほしい。あなたの見解も欲しい
- AIチェック結果: 仕様は warnings のみ、実装は warnings + suggestions あり。SPEC.md 側に suggestions を追加して良いですか？
    * OK
- Publishの冪等性: 仕様は「重複は成功応答で処理スキップ」。実装は AlreadyPublished で 409 Conflict。どちらを正としますか？
    * よくわからないので言い換えてまた質問してほしい。あなたの見解も欲しい
- PublishとAdapter送信: 仕様は「publish時にAdapter経由でChat A送信」。現実装は送信処理なし。仕様に「未実装/後で追加」を明記しますか？
    * 
- Idempotencyの保存場所: 仕様はDB/Redisでのユニーク制約。現実装は MessageRepository のメモリ保持のみ。仕様を簡略化（インメモリ）へ寄せますか？
    * コード側の不足です。DBはPostgreSQLかDuckDB
- TicketのJSONレスポンス: ticket_to_json は chatA/lastPublicAt/assignees 等を返していません。仕様側はフルモデル前提ですが、API仕様を縮小してもいいですか？
    * ダメ
- MessageのJSONレスポンス: 仕様は attachments/replyToMessageId/idempotencyKey などを持つが、実装レスポンスは多くが省略されています。仕様を実装に合わせて縮小しますか？
    * ダメ
- 返信/スレッド: replyToMessageId を仕様で重視しますか？（現状UI/ハンドラで使っていない）
    * よくわからないので言い換えてまた質問してほしい。あなたの見解も欲しい
- 添付ファイル: 仕様は署名URL＋リンク共有。現実装は添付処理なし＆Direct adapterは添付不可。仕様を「添付は未対応」に下げますか？
    * ユーザーは添付ファイルをつけてくる。airlock/it-support-app としては自動でBox.com/kintone とかに保存するような仕組みが欲しい。
- Loop防止: 仕様は source: console メタ付与やsenderチェック。実装は sender_id/is_bot でのみ除外。仕様を実装に合わせて簡略化しますか？
    * ダメ
- Ticket Inboxの表示項目: 仕様は assignees/lastPublicAt/ドラフトバッジなど。現状UIは subject/status のみ。仕様を簡略化しますか？
    * ダメ
- ログ/外部化: spec/DOMAIN.md は DuckDB/Parquet 出力の記述があるが、実装はDuckDBへのログ保存のみ。Parquet出力は仕様から外しますか？それとも残しますか？
    * 残す。必要に応じてロードする方が良くない？
- データストア: 仕様は「Core DBが正」。実装はインメモリRepo。仕様に「暫定インメモリ」を明記して良いですか？
    * 暫定ならOK
- APIパス: 仕様は /api/... 前提ですが、UIは /tickets/... のHTMXフォームです。仕様にHTML用ルートも加えますか？
    * 使用を更新。HATEOASにしたい
- Chat Aの対象: spec/DOMAIN.md は direct4b前提、spec/SPEC.md はSlack/Teams等の一般化。どちらを優先しますか？（SPECをdirect4b寄りに寄せる？）
    * ユーザー利用はdirect4b前提。
- 「公開は状態遷移」: 現状は visibility=public に上書き。仕様は「複製 or 上書き」。どちらに寄せますか？
    * あなたのおすすめは？

## 追加で確認したい点（見解つき）

1. Draft作成 → AIチェックの自動開始について
  - いま：作成時は Pending のまま。recheck を呼ぶと Checking。
  - 仕様案（私のおすすめ）：Draft作成時に自動でCheckingへ（非同期実行）。ただしMVPは「AI未実装のため即 Pending」でもよいので、仕様に 「本来は自動、暫定は手動recheck」 を併記するのが現実的。
  - → 質問: 仕様は「自動チェックが基本、暫定は手動」方針で記述していいですか？
  - ⇢ 回答: 保留の機能。織り込めるようにインターフェースを残しておいてほしい。

2. Publishの冪等性（同一ドラフトを再Publishした時のレスポンス）
  - 仕様: 成功扱いで処理スキップ
  - 実装: 409 Conflict
  - 仕様案（私のおすすめ）：同じidempotencyKeyなら 200/201 で同じ結果を返す（クライアントが安心できる）。
  - → 質問: 冪等な再Publishは 200で同じ結果返却 に寄せて良いですか？
  - → 追加で、idempotencyKeyなしの再Publish も 200 にするか、それとも 409 のままにしますか？
  - ⇢ 回答: 200/201 で同じ結果を返す（クライアントが安心できる）

3. replyToMessageId（スレッド）
  - 仕様は保持、実装/UIは未使用。
  - 仕様案（私のおすすめ）：保持は必須だがUI/挙動は「将来対応」 と明記。
  - → 質問: 仕様に「保存は必須、UIは未対応」を明記して良いですか？
  - ⇢ 回答: OK

4. Publish時のAdapter送信

  - 現状コードは送信処理なし。
  - 仕様案：MVPでは未実装（TODO）、将来必須 と明記。
  - → 質問: Publish時の外部送信は 必須仕様として残すが実装は未了 と記述してよいですか？
  - ⇢ 回答: OK

5. 添付ファイルの扱い（Box.com / kintone等）

  - ご要望: ユーザー添付は自動保存。
  - 仕様案：「Attachment Storage Service」(Box/kintone/他) を導入し、受信時に外部保存→リンク化 を要件化。
    → 質問: まずは Box.com優先 / kintone優先 / 両対応前提 のどれで書きますか？
    → どの段階でリンク化しますか？
      - A) 受信時に即保存してリンク置換
      - B) チェック/公開時に保存・リンク化
      - C) 両方（冪等に）
  - ⇢ 回答: ごめん、そもそもこういうやり方ができるのか、とあなたのおすすめを教えて欲しい

6. 公開処理のモデル（複製 or 上書き）

  - 実装は同一メッセージを visibility=public に更新。
  - 仕様案（私のおすすめ）：単一レコード更新＋ログで履歴保全。
    → 質問: 単一レコード更新 方針で spec を寄せていいですか？
    （「draftを残したい」場合は、ログやイベントで残す設計に寄せます）
  - ⇢ 回答: 単一レコード更新 方針で spec を寄せていいよ。

7. データストアの方針（PostgreSQL / DuckDB）

  - 回答: DBはPostgreSQLかDuckDB
  - 仕様案：運用DBはPostgreSQL、監査・外部化はDuckDB/Parquet
    → 質問: これで固定して書いていいですか？それとも「どちらも選択可能」と抽象化しますか？
  - ⇢ 回答: どちらも選択可能

8. HATEOAS 方針

  - 要望: “仕様更新。HATEOASにしたい”
    → 質問: APIレスポンスに _links を付与する方針で書いて良いですか？
      - 例: ticket に timeline, items, drafts, publish などのリンク
        → UI側のHTMXフォームも リンクから構築する 方針まで含めますか？
  - ⇢ 回答: ここで言うAPIレスポンスってなんのこと？

9. 「両方です」の意味合い

  - 現状コードに合わせてspec更新 ＋ specを正として後で実装を追随
    → 質問: spec内に 「現状(MVP)」と「To-Be(完全形)」の二段構え を入れてよいですか？
    （この書き方だと、ギャップが残っても運用で混乱しにくいです）
  - ⇢ 回答: spec内に 「現状(MVP)」と「To-Be(完全形)」の二段構えでOK

## 確認したい残りの点（最終決定用）
1. Draft自動チェックの扱い

  - いただいた回答: 「保留の機能。織り込めるようにインターフェースを残して」
  - 私の提案（spec記述）:
      - 現状(MVP): Draft作成時は Pending のまま。
      - To‑Be: Draft作成後に自動で Checking へ遷移（非同期）。
      - 仕様: 自動チェックのフック/インターフェースを必須で定義。
        → この書き方で確定して良いですか？
  - ⇢ 回答: OKです。

2. Publish冪等性（idempotencyKeyなし再Publishの扱い）

  - いただいた回答: 同じidempotencyKeyなら 200/201 で同じ結果返却
  - 未回答: idempotencyKeyが無い/違う 再Publish
    → 仕様としてどれが良いですか？
      - A) 必須（keyなしは 400）
      - B) 409（すでに公開済みは衝突）
      - C) 200（状態に関係なく最新を返す）
  - ⇢ 回答: ごめん、おすすめでよろしく

3. 添付ファイルの実現方法（おすすめ）

  - ご要望: ユーザー添付は 自動保存（Box/kintone等）
  - 私のおすすめ:
      - AttachmentStorage を抽象化（Box/kintone/S3等のドライバ差し替え）
      - 受信時に即保存(A) を基本（タイムラインの一貫性と再送・参照が安定）
      - UI/送信は保存先の署名URLで扱う
        → 仕様は「抽象化＋受信時保存(A)」で書いて良いですか？
        → まず Box優先 / kintone優先 / 両対応前提 どれで書きますか？
  - ⇢ 回答: 抽象化＋受信時保存(A)

4. HATEOASの「APIレスポンス」の意味

  - 私が想定している「APIレスポンス」＝ HTTP JSONレスポンス（/api/...）。
  - 例:

    {
      "ticket_id": "...",
      "_links": {
        "timeline": { "href": "/api/tickets/{id}/timeline", "method": "GET" },
        "drafts": { "href": "/api/tickets/{id}/drafts", "method": "POST" }
      }
    }

  → この理解で合っていますか？
  → /apiのJSONだけに _links を付ける方針で良いですか？
  それとも HTML(HTMX)側にもリンク駆動 を明記しますか？

  - ⇢ 回答: HTMXに寄せて
