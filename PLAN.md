# Airlock Direct Bridge 安定化計画

## 目的

`opz direct-api-dev -- just direct-prepare-rest && opz daab-dev -- just app` で起動したとき、時間経過後に Direct メッセージ受信が止まる問題を解消する。

## 実装方針

1. `DirectAdapter` に死活監視用 API (`is_connected`, `is_authenticated`) を追加する。
2. `SESSION_ERROR / NOTIFICATION_ERROR / DECODE_ERROR` で `AdapterState::Error` を立てる。
3. `it_support_app` の再接続ループで以下を実施する。
   - 接続状態を定期監視し、不健康なら adapter を破棄して再接続へ移行。
   - 再接続前に `daab login --force` 相当を自動実行して Bot トークンを再取得。
   - 失敗時は指数バックオフ（最大 60 秒）で再試行。
4. 起動手順を `just app-stable` に統合する。
   - `direct-prepare-rest`
   - `direct-prepare-bot`
   - `app-up`（`opz daab-dev` 経由）

## 変更対象

- `src/adapters/direct_adapter.mbt`
- `src/cmd/it_support_app/main_native.mbt`
- `justfile`

## 受け入れ条件

1. セッション失効後もプロセス再起動なしで自動復旧する。
2. `just app-stable` を実行すれば REST/Bot の準備と起動が一貫して完了する。
3. トークン失敗時のログが `direct-health` / `direct-relogin` / `direct-reconnect` プレフィックスで追跡できる。
