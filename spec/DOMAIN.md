## システム概要
- 会社で使用している chat (direct4b, use ../direct_sdk) と連携するサポート担当者向け問い合わせ管理・応答システム (it-support-app)
- 業務属人化低減、効率的な問い合わせ窓口運用
  - direct4b は1アカウントにつき利用者が1名
  - そのため direct4b には ITサポート窓口というユーザーアカウントを作成できない
  - direct4b には ITサポート窓口という bot アカウントを置く
  - direct4b の各ユーザーはトークルーム (like DM) で ITサポート窓口に質問する
  - ITサポート窓口 bot はメッセージを it-support-app に投稿 (routing, transfer) する
  - it-support-app では1名以上の担当者が対応する
  - 窓口内でやりとりを行い、確定した回答のみ direct4b のトークルームに回答する
  - it-support-app と direct4b の接続は f4ah6o/direct_sdk を利用する
  - この仕組みは direct4b (n:m) だったユーザー(n)とITサポート担当者(m)の関係を
    - direct4b(n:1) - it-support-app(1:m) にする
    - さらに direct4b(メッセージ) だったのを direct4b:it-support-app(チケット) に変換する
    - チケット単位で管理することで、ログを外部化できる

## 添付ファイル
- ユーザー添付は **自動で外部保存** する
- AttachmentStorage を抽象化し、Box/kintone/S3等のドライバを差し替え可能にする
- 優先順位は **Box > kintone > others**
- 受信時に即保存し、アプリ内はリンク (署名URL) で扱う

## 問い合わせ管理・応答システム
- 3pane構造（左チケットリスト、中チャット、右担当者メモ/ドラフト）
- チケットリスト
  - direct4b で ITサポートボットへのメッセージがチケットとしてリスト
  - close チケットは parquet で出力
  - チケットを選択するとチャットにやり取りが表示される
  - 担当者メモは ITサポート担当者間でやり取りする

## ログ/外部化
- ログは DuckDB に保存し、必要に応じて Parquet 出力・再ロードできるようにする

## データストア
- MVP はインメモリ
- To‑Be は PostgreSQL / DuckDB を選択可能
