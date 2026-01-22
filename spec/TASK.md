# 作業タスク細分化 (PLAN.md 由来)

## MVP / Phase 1-3 (基盤)
- [ ] MoonBitプロジェクト構造の確認と不足の洗い出し
- [ ] `moon.mod.json` / `moon.pkg` の整合確認
- [ ] TMPX/HTMX の依存/配置方法を確定（HTMXはvendor方針）
- [ ] Adapter最小構成（direct4b）の接続設計を明文化
- [ ] Core/Adapter/API/Web の責務境界をREADMEかSPECに追記

## Core データモデル
- [ ] Ticket型の必須フィールド整理（chatA/assignees/lastPublicAt/lockVersion）
- [ ] Message型の必須フィールド整理（attachments/replyToMessageId/idempotencyKey）
- [ ] Attachment/AICheckResult 仕様の整合確認（warnings/suggestions）
- [ ] DraftStatus 遷移図の最終版を SPEC に合わせて更新

## Repository / Store
- [ ] In-memory Repo のCRUDと一覧フィルタ仕様の明文化
- [ ] Idempotency Key の保存/重複判定の仕様化
- [ ] DB切替(PostgreSQL/DuckDB)方針の記述（To‑Be）

## Draft / Check / Publish
- [ ] Draft作成時の状態 (Pending) と Recheck の契約を確定
- [ ] 自動チェック用インターフェース設計（To‑Be）
- [ ] Publishのサーバーガード仕様を整理
- [ ] Publishの冪等性（同一キーは同結果、key必須）を明記
- [ ] Publish時の外部送信（Adapter）を To‑Be として規定

## Attachment Storage
- [ ] AttachmentStorage 抽象化の責務/境界を定義
- [ ] 受信時保存 + 署名URL運用の仕様追加
- [ ] 優先順位 (Box > kintone > others) の運用メモ追加

## UI (HTMX/TMPX)
- [ ] 3ペインの責務定義と誤爆防止のUX方針をSPECに反映
- [ ] HTMXのpartial更新パス設計（/partials/ticket/{id} など）
- [ ] Pane2の公開操作を Draft→Check→Publish に統合する方針を明文化
- [ ] Pane3の内部チャット/ドラフト/レビュー表示要件の整理
- [ ] Ticket Inboxの表示項目（assignees/lastPublicAt/ドラフトバッジ）を明記

## API (To‑Be)
- [ ] /api のJSONレスポンスは全フィールド返却と明記
- [ ] replyToMessageId の保存必須・UI将来対応を明記
- [ ] HATEOASはHTML(HTMX)に集約する方針を明記

## Logging / Audit
- [ ] DuckDBログの保存項目とイベント種別の整理
- [ ] Parquet出力と再ロードの運用メモ追加

## テスト/検証 (To‑Be)
- [ ] State machine テストパターン整理
- [ ] Repository idempotency のテストケース整理
- [ ] Draft→Publish フローのE2E確認項目整理
