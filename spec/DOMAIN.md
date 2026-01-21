## システム概要
* 会社で使用しているchat (direct4b, use ../direct_sdk)と連携するサポート担当者向け問い合わせ管理・応答システム(it-support-app)
* 業務属人化低減、効率的な問い合わせ窓口運用
   * direct4b は1アカウントにつき利用者が1名
   * そのためdirect4bにはITサポート窓口というユーザーアカウントを作成できない
   * direct4bにはITサポート窓口というbotアカウントを置く。
   * direct4bの各ユーザーはトークルーム（like DM）でITサポート窓口に質問する
   * ITサポート窓口botはメッセージをit-support-appに投稿(routing, transfer)する
   * it-support-appでは1名以上の担当者が対応する。窓口内でやりとりを行い、確定した回答のみdirect4bのトークルームに回答する。
   * it-support-appとdirect4bの接続は f4ah6o/direct_sdk を利用する
   * この仕組みはdirect4b(n:m)だったユーザー(n)とITサポート担当者(m)の関係を
     * direct4b(n:1)-it-support-app(1:m)にする。
     * さらにdirect4b(メッセージ）だったのをdirect4b:it-support-app(チケット）に変換する
     * チケット単位で管理することで、ログを外部化できる。
     * logはduckdb.mbtを使ってduckdb(parquet）で外部化する
## 問い合わせ管理・応答システム
  * 3pane構造（左チケットリスト、中チャット、右担当者メモ）
### チケットリスト
* direct4bでITサポートボットへのメッセージがチケットとしてリスト
* closeチケットはparquetで出力
* チケットを選択するとチャットにやり取りが表示される
* 担当者メモはITサポート担当者間でやり取りする。
