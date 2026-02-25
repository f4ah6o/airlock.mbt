# Airlock Group-First Chat + Keycloak Integration Plan

## Summary

Airlock をチケット中心から **group-first** モデルに移行し、以下を実現する。

- `it_support_app` に `group` / `user` 概念を導入
- ChatA 受信を `(platform, bot_account_id, channel_id)` で `group` にルーティング
- `chat` と `notes` を group 境界で分離
- 認証・認可の境界を Keycloak 前提で統一
- 公開ルートを `/{group_id}` で提供（運用ドメイン例: `grp.obr-grp.com/{group_id}`）

## Design Decisions

1. テナント境界は `Group` とする
2. ルーティングキーは `platform + bot_account_id + channel_id`
3. 認可は `GroupRole`（`owner/manager/agent/viewer`）で統一
4. 画面ルートは group prefix (`/{group_id}`) を正とする
5. 後方互換は必須要件にしない（実装は段階移行）

## Public API / Interface Changes

### shared (`src/shared/types.mbt`)

- 追加:
  - `GroupRole`, `GroupStatus`, `Group`, `GroupMember`, `Identity`, `RouteBinding`
- 変更:
  - `ChatAMetadata` に `bot_account_id`
  - `InboundMessage` に `bot_account_id`
  - `Ticket` に `group_id`
  - `Message` に `group_id`

### core (`src/core/repository.mbt`, `src/core/inbound_ingest.mbt`)

- 追加:
  - `GroupRepository`, `GroupMemberRepository`, `RouteBindingRepository`
  - `TicketRepository::list_by_group*`
  - `MessageRepository::list_*_by_group`
- 変更:
  - `IngestContext` に `route_binding_repo`
  - 受信 dedupe key を `inbound:{platform}:{bot_account_id}:{external_id}` に拡張
  - route binding が存在する場合は group 解決を必須化

### api (`src/api/handlers.mbt`)

- 追加ルート:
  - `GET /api/groups/{group_id}/tickets`
  - `GET /api/groups/{group_id}/chat`
  - `GET /api/groups/{group_id}/notes`
  - `POST /api/groups/{group_id}/notes`
  - `GET /api/groups/{group_id}/tickets/{ticket_id}`
  - `POST /api/groups/{group_id}/tickets/{ticket_id}/reply`
- 変更:
  - `AppContext` に `group_member_repo`
  - group ルートで membership / post 権限を強制
  - Ticket/Message JSON に `group_id` と関連メタデータを追加

### auth (`src/auth/*`) 新規

- `AuthConfig`, `Principal`, `AuthError`
- `principal_from_headers` による Keycloak 連携前提の principal 復元
- `build_keycloak_login_url` で passkey hint を含むログインURL生成

### it_support_app (`src/cmd/it_support_app/main_native.mbt`)

- group prefix ルーティングの追加
- `/{group_id}` 系アクセスで認証・認可チェック
- group-scoped partial と SSE フィルタリング
- route binding を Direct bridge 起動時に同期

## Test Scenarios

1. Group route / RBAC
- `group handlers list tickets and post note`
- `group handlers reject non-member user`

2. Inbound routing
- `ingest_incoming resolves group via route binding`
- `ingest_incoming rejects unknown route binding when bot_account_id is present`

3. Repository behavior
- group list/filter の追加メソッド
- route binding resolve/delete
- group member post permission

4. Auth utility
- header principal parsing
- group access validation
- passkey hint を含む Keycloak login URL

## Assumptions / Defaults

- PLAN 保存先は `spec/PLAN.md`
- Keycloak は central realm + app clients を想定
- `it_support_app` は `X-Auth-*` ヘッダー連携（ID プロキシ/OIDC中継）を前提
- 開発モードでは `support` principal をフォールバック許可
- `@shared.default_group_id()` は bootstrap group として利用

## Validation Commands

```bash
moon check --deny-warn --target native
moon test --target native
moon info
moon fmt
```
