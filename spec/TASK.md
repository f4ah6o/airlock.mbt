# 作業タスク細分化 (PLAN.md 由来)

## 凡例
- 優先度: P0=最優先, P1=重要, P2=余裕
- 種別: doc=仕様/計画, impl=実装/運用

## MVP / Phase 1-3 (基盤)
- [x] [P0][impl] MoonBitプロジェクト構造の確認と不足の洗い出し
- [x] [P0][impl] `moon.mod.json` / `moon.pkg` の整合確認
- [x] [P0][doc] TMPX/HTMX の依存/配置方法を確定（HTMXはvendor方針）
- [x] [P0][impl] Adapter最小構成（direct4b）の接続設計を明文化
- [x] [P1][doc] Core/Adapter/API/Web の責務境界をREADMEかSPECに追記

## Core データモデル
- [x] [P0][doc] Ticket型の必須フィールド整理（chatA/assignees/lastPublicAt/lockVersion）
- [x] [P0][doc] Message型の必須フィールド整理（attachments/replyToMessageId/idempotencyKey）
- [x] [P1][doc] Attachment/AICheckResult 仕様の整合確認（warnings/suggestions）
- [x] [P0][doc] DraftStatus 遷移図の最終版を SPEC に合わせて更新

## Repository / Store
- [x] [P0][doc] In-memory Repo のCRUDと一覧フィルタ仕様の明文化
- [x] [P0][doc] Idempotency Key の保存/重複判定の仕様化
- [x] [P1][doc] DB切替(PostgreSQL/DuckDB)方針の記述（To‑Be）

## Draft / Check / Publish
- [x] [P0][doc] Draft作成時の状態 (Pending) と Recheck の契約を確定
- [x] [P1][doc] 自動チェック用インターフェース設計（To‑Be）
- [x] [P0][doc] Publishのサーバーガード仕様を整理
- [x] [P0][doc] Publishの冪等性（同一キーは同結果、key必須）を明記
- [x] [P1][doc] Publish時の外部送信（Adapter）を To‑Be として規定

## Attachment Storage
- [x] [P1][doc] AttachmentStorage 抽象化の責務/境界を定義
- [x] [P1][doc] 受信時保存 + 署名URL運用の仕様追加
- [x] [P1][doc] 優先順位 (Box > kintone > others) の運用メモ追加

## UI (HTMX/TMPX)
- [x] [P0][doc] 3ペインの責務定義と誤爆防止のUX方針をSPECに反映
- [x] [P0][doc] HTMXのpartial更新パス設計（/partials/ticket/{id} など）
- [x] [P1][doc] Pane2の公開操作を Draft→Check→Publish に統合する方針を明文化
- [x] [P1][doc] Pane3の内部チャット/ドラフト/レビュー表示要件の整理
- [x] [P1][doc] Ticket Inboxの表示項目（assignees/lastPublicAt/ドラフトバッジ）を明記

## API (To‑Be)
- [x] [P1][doc] /api のJSONレスポンスは全フィールド返却と明記
- [x] [P1][doc] replyToMessageId の保存必須・UI将来対応を明記
- [x] [P1][doc] HATEOASはHTML(HTMX)に集約する方針を明記

## Logging / Audit
- [x] [P1][doc] DuckDBログの保存項目とイベント種別の整理
- [x] [P1][doc] Parquet出力と再ロードの運用メモ追加

## テスト/検証 (To‑Be)
- [x] [P2][impl] State machine テストパターン整理
- [x] [P2][impl] Repository idempotency のテストケース整理
- [x] [P2][impl] Draft→Publish フローのE2E確認項目整理
