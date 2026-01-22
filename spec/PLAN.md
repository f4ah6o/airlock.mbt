# Airlock - IT Support Chat System Implementation Plan

## Project Overview

Build a support staff management system (Chat B) that integrates with internal inquiry channels (Chat A) using Moonbit and the Core/Adapter architecture.

**Primary Goals:**
- Prevent accidental message sending (誤爆の完全防止)
- Ensure uniform support quality (サポート品質の均一化)

---

## Phase 1: Project Foundation

### 1.1 Environment Setup
- [ ] Initialize Moonbit project structure
- [ ] Configure build toolchain (moon.mod.json, etc.)
- [ ] Set up development environment with hot reload
- [ ] Configure linting and formatting rules

### 1.2 Dependencies Integration
- [ ] Integrate TMPX for server-side HTML generation
- [ ] Integrate HTMX (vendored JS) for progressive enhancement
- [ ] Integrate [direct_sdk.mbt](https://github.com/f4ah6o/direct_sdk.mbt) for initial adapter
- [ ] Create placeholder modules for future adapters (Discord, Slack)

### 1.3 Core Architecture Scaffolding
- [ ] Create directory structure:
  ```
  src/
  ├── core/           # Platform-independent business logic
  ├── adapters/       # Chat A platform integrations
  ├── web/            # TMPX view/layouts (SSR)
  ├── api/            # HTTP API handlers
  └── shared/         # Common types and utilities
  ```
- [ ] Define module boundaries and interfaces
- [ ] Set up error handling patterns

---

## Phase 2: Core Data Layer

### 2.1 Data Models (Types)
- [ ] Define `Ticket` type with all fields from SPEC:
  - ticketId, status (open/closed/pending)
  - chatA metadata (platform, dmId, lastInboundCursor)
  - assignees, lastPublicAt, lockVersion
  - timestamps (createdAt, updatedAt)
- [ ] Define `Message` type:
  - messageId, ticketId, text, attachments
  - replyToMessageId for threading
  - visibility (public/internal), origin (chatA/console/system)
  - isDraft, draftStatus (pending/checking/checked/published)
  - aiCheckResult, idempotencyKey, publishedAt
  - senderId, timestamp
- [ ] Define `Attachment` type (type, url, name)
- [ ] Define `User`/`Admin` types for identity management

### 2.2 State Machine Implementation
- [ ] Implement draft status state machine:
  ```
  [Draft Created] → pending
       ↓
  [AI Check Triggered] → checking
       ↓
  [Check Complete] → checked | rejected
       ↓
  [Publish Action] → published
  ```
- [ ] Add validation guards for each transition
- [ ] Implement optimistic locking with `lockVersion`

### 2.3 Storage Layer
- [ ] Design in-memory store interface (for initial development)
- [ ] Implement Ticket repository (CRUD + queries)
- [ ] Implement Message repository with visibility filtering
- [ ] Add idempotency key tracking for publish operations

---

## Phase 3: Adapter Layer

### 3.1 Adapter Interface
- [ ] Define `Adapter` trait/interface:
  ```moonbit
  trait Adapter {
    listen_incoming(callback: (NormalizedMessage) -> Unit) -> Unit
    send_outbound(message: OutboundMessage) -> Result[SendResult, AdapterError]
    get_platform_name() -> String
  }
  ```
- [ ] Define normalized message types for cross-platform compatibility

### 3.2 Direct Adapter (Primary)
- [ ] Implement adapter using direct_sdk.mbt
- [ ] Handle incoming message normalization
- [ ] Implement outbound message sending
- [ ] Add reflection/loop prevention (sender ID check)

### 3.3 Adapter Registry
- [ ] Create adapter factory/registry pattern
- [ ] Support multiple simultaneous adapters
- [ ] Handle adapter lifecycle (connect, disconnect, reconnect)

---

## Phase 4: API Layer

### 4.1 HTTP Server Setup
- [ ] Set up HTTP server (using available Moonbit web framework)
- [ ] Configure CORS and security headers
- [ ] Implement request/response serialization (JSON)

### 4.2 Ticket Endpoints
- [ ] `GET /api/tickets?status=open` - Fetch inbox
- [ ] `GET /api/tickets/{id}` - Get ticket details

### 4.3 Timeline Endpoint (Pane 2)
- [ ] `GET /api/tickets/{id}/timeline` - Public messages only

### 4.4 Workspace Endpoints (Pane 3)
- [ ] `GET /api/tickets/{id}/items` - All messages (internal + public)
- [ ] `POST /api/tickets/{id}/notes` - Create internal note
- [ ] `POST /api/tickets/{id}/drafts` - Create draft
- [ ] `PUT /api/tickets/{id}/drafts/{msgId}` - Update draft
- [ ] `POST /api/tickets/{id}/drafts/{msgId}/recheck` - Trigger AI recheck
- [ ] `POST /api/tickets/{id}/drafts/{msgId}/publish` - Publish draft (state transition)

### 4.5 Publish Safety Implementation
- [ ] Server-side guard: Verify `draftStatus === checked` before publish
- [ ] Idempotency check using idempotencyKey
- [ ] Prevent destination (chatA.dmId) modification

---

## Phase 5: UI Implementation

### 5.1 Layout Foundation
- [ ] Create 3-pane responsive layout using TMPX (SSR)
- [ ] Implement HTMX partial updates (ticket selection / note updates)
- [ ] Set up basic navigation state (selected ticket)

### 5.2 Pane 1: Ticket Inbox (Left)
- [ ] Ticket list component with filtering
- [ ] Display: user info, subject, elapsed time, assignee icons
- [ ] Draft status badge indicator
- [ ] Ticket selection handler

### 5.3 Pane 2: Public Timeline (Center)
- [ ] Public message timeline component
- [ ] Message bubble rendering (user vs support)
- [ ] Attachment display (images, files)
- [ ] Thread/reply visualization
- [ ] **誤爆防止フローに統合** (To‑Be: Draft → Check → Publish)

### 5.4 Pane 3: Workspace (Right)
- [ ] Visual distinction with background color (#fffbe6)
- [ ] Internal notes chat section
- [ ] Draft editor with mode toggle (Note vs Draft)
- [ ] Review panel for AI feedback
- [ ] Action buttons: Submit Draft, Recheck, Publish
- [ ] Publish confirmation modal

### 5.5 Real-time Updates
- [ ] WebSocket connection for live updates
- [ ] Optimistic UI updates with rollback
- [ ] New message notifications

---

## Phase 6: AI Check Integration

### 6.1 Check Interface
- [ ] Define AI check service interface
- [ ] Implement check request/response types

### 6.2 Mock Implementation
- [ ] Create mock AI checker for development
- [ ] Simulate check delays and results
- [ ] Generate sample warnings/suggestions

### 6.3 Integration
- [ ] Wire AI check into draft creation flow
- [ ] Display check results in Review Panel
- [ ] Handle check failures gracefully

---

## Phase 7: Safety & Reliability

### 7.1 Idempotency System
- [ ] Implement idempotency key generation (client-side)
- [ ] Server-side key validation and deduplication
- [ ] Handle concurrent publish attempts

### 7.2 Loop Prevention
- [ ] Implement sender ID filtering in adapters
- [ ] Add `source: console` metadata to outbound messages
- [ ] Validate all inbound messages before processing

### 7.3 Error Handling
- [ ] Define error taxonomy (network, validation, authorization)
- [ ] Implement retry logic with backoff
- [ ] User-friendly error messages in UI

### 7.4 Audit Logging
- [ ] Log all publish operations
- [ ] Log state transitions with timestamps
- [ ] Track user actions for debugging

### 7.5 Attachment Storage
- [ ] Define AttachmentStorage interface (Box/kintone/S3 driver)
- [ ] Ingest inbound attachments on receive
- [ ] Store external links (signed URLs)

---

## Phase 8: Testing

### 8.1 Unit Tests
- [ ] Core data model tests
- [ ] State machine transition tests
- [ ] Repository operation tests
- [ ] Validation logic tests

### 8.2 Integration Tests
- [ ] API endpoint tests
- [ ] Adapter integration tests
- [ ] End-to-end workflow tests (Draft → Check → Publish)

### 8.3 Safety Tests
- [ ] Idempotency verification tests
- [ ] Loop prevention tests
- [ ] Concurrent operation tests

---

## Phase 9: Documentation & Polish

### 9.1 Documentation
- [ ] API documentation
- [ ] Architecture decision records
- [ ] User guide for support staff
- [ ] Deployment guide

### 9.2 Performance Optimization
- [ ] Profile and optimize critical paths
- [ ] Implement caching where appropriate
- [ ] Optimize bundle size

---

## Implementation Priority Matrix

| Priority | Component | Rationale |
|----------|-----------|-----------|
| P0 | Data Models + State Machine | Foundation for everything |
| P0 | Publish Safety (Idempotency, Guards) | Core safety requirement |
| P1 | Basic UI (3 Panes) | User interaction |
| P1 | Draft → Publish Workflow | Primary use case |
| P1 | Direct Adapter | Platform connectivity |
| P2 | AI Check Integration | Quality assurance |
| P2 | Real-time Updates | UX enhancement |
| P3 | Additional Adapters (Slack, Discord) | Platform expansion |
| P3 | Performance Optimization | Scale preparation |

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Moonbit library gaps | Build missing functionality; don't use JS/TS alternatives |
| Adapter SDK instability | Abstract behind interface; prepare fallback implementations |
| Message delivery failure | Implement retry with exponential backoff; provide manual retry UI |
| Accidental publish | Multiple safeguards: UI confirmation, server-side guards, idempotency |

---

## Success Criteria

1. **Zero accidental publishes** - All messages go through Draft → Check → Publish flow
2. **Platform independence** - Core logic works regardless of Chat A platform
3. **Auditability** - All actions are logged and traceable
4. **Responsiveness** - UI updates reflect state changes within 500ms
5. **Reliability** - Graceful handling of network failures and concurrent operations
