///|
/// HTTP API Handlers
/// Implements all REST endpoints for the Airlock system

/// =============================================================================
/// Application Context (Dependencies for handlers)
/// =============================================================================

///|
/// Application context containing repositories and services
pub(all) struct AppContext {
  ticket_repo : @core.TicketRepository
  message_repo : @core.MessageRepository
  group_member_repo : @core.GroupMemberRepository
  current_timestamp : () -> String // Function to get current time
  generate_id : () -> String // Function to generate unique IDs
  log_store : @logs.LogStore?
}

///|
/// Create a new application context
pub fn AppContext::new(
  ticket_repo : @core.TicketRepository,
  message_repo : @core.MessageRepository,
  current_timestamp : () -> String,
  generate_id : () -> String,
  group_member_repo? : @core.GroupMemberRepository = @core.GroupMemberRepository::new(),
  log_store? : @logs.LogStore,
) -> AppContext {
  {
    ticket_repo,
    message_repo,
    group_member_repo,
    current_timestamp,
    generate_id,
    log_store,
  }
}

/// =============================================================================
/// Route Matching
/// =============================================================================

///|
/// Parsed route information
pub(all) enum Route {
  // Group routes (group-first)
  ListGroupTickets(String) // GET /api/groups/{group_id}/tickets
  GetGroupChat(String) // GET /api/groups/{group_id}/chat
  GetGroupNotes(String) // GET /api/groups/{group_id}/notes
  CreateGroupNote(String) // POST /api/groups/{group_id}/notes
  GetGroupTicket(String, String) // GET /api/groups/{group_id}/tickets/{ticket_id}
  ReplyGroupTicket(String, String) // POST /api/groups/{group_id}/tickets/{ticket_id}/reply

  // Ticket routes
  ListTickets // GET /api/tickets
  GetTicket(String) // GET /api/tickets/{id}

  // Timeline routes
  GetTimeline(String) // GET /api/tickets/{id}/timeline

  // Workspace routes
  GetWorkspaceItems(String) // GET /api/tickets/{id}/items
  CreateNote(String) // POST /api/tickets/{id}/notes
  CreateDraft(String) // POST /api/tickets/{id}/drafts
  UpdateDraft(String, String) // PUT /api/tickets/{id}/drafts/{msgId}
  RecheckDraft(String, String) // POST /api/tickets/{id}/drafts/{msgId}/recheck
  PublishDraft(String, String) // POST /api/tickets/{id}/drafts/{msgId}/publish

  // Unknown route
  NotFound
} derive(Show, Eq)

///|
/// Parse request path into route
pub fn parse_route(http_method : HttpMethod, path : String) -> Route {
  let parts = split_path(path)
  let len = parts.length()

  // Group-first routes:
  // /api/groups/{group_id}/...
  if len >= 3 && parts[0] == "api" && parts[1] == "groups" {
    let group_id = parts[2]
    match http_method {
      Get =>
        if len == 4 && parts[3] == "tickets" {
          ListGroupTickets(group_id)
        } else if len == 4 && parts[3] == "chat" {
          GetGroupChat(group_id)
        } else if len == 4 && parts[3] == "notes" {
          GetGroupNotes(group_id)
        } else if len == 5 && parts[3] == "tickets" {
          GetGroupTicket(group_id, parts[4])
        } else {
          NotFound
        }
      Post =>
        if len == 4 && parts[3] == "notes" {
          CreateGroupNote(group_id)
        } else if len == 6 && parts[3] == "tickets" && parts[5] == "reply" {
          ReplyGroupTicket(group_id, parts[4])
        } else {
          NotFound
        }
      _ => NotFound
    }
  } else {

    // Legacy ticket routes.
    if len < 2 || parts[0] != "api" || parts[1] != "tickets" {
      return NotFound
    }
    match http_method {
      Get =>
        if len == 2 {
          // GET /api/tickets
          ListTickets
        } else if len == 3 {
          // GET /api/tickets/{id}
          GetTicket(parts[2])
        } else if len == 4 && parts[3] == "timeline" {
          // GET /api/tickets/{id}/timeline
          GetTimeline(parts[2])
        } else if len == 4 && parts[3] == "items" {
          // GET /api/tickets/{id}/items
          GetWorkspaceItems(parts[2])
        } else {
          NotFound
        }
      Post =>
        if len == 4 && parts[3] == "notes" {
          // POST /api/tickets/{id}/notes
          CreateNote(parts[2])
        } else if len == 4 && parts[3] == "drafts" {
          // POST /api/tickets/{id}/drafts
          CreateDraft(parts[2])
        } else if len == 6 && parts[3] == "drafts" && parts[5] == "recheck" {
          // POST /api/tickets/{id}/drafts/{msgId}/recheck
          RecheckDraft(parts[2], parts[4])
        } else if len == 6 && parts[3] == "drafts" && parts[5] == "publish" {
          // POST /api/tickets/{id}/drafts/{msgId}/publish
          PublishDraft(parts[2], parts[4])
        } else {
          NotFound
        }
      Put =>
        if len == 5 && parts[3] == "drafts" {
          // PUT /api/tickets/{id}/drafts/{msgId}
          UpdateDraft(parts[2], parts[4])
        } else {
          NotFound
        }
      Delete => NotFound
    }
  }
}

///|
/// Split path into segments
fn split_path(path : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  for i = 0; i < path.length(); i = i + 1 {
    let c = path[i]
    if c == '/' {
      if current != "" {
        result.push(current)
        current = ""
      }
    } else {
      current = current + c.unsafe_to_char().to_string()
    }
  }
  if current != "" {
    result.push(current)
  }
  result
}

/// =============================================================================
/// Main Router
/// =============================================================================

///|
/// Handle incoming HTTP request
pub fn handle_request(ctx : AppContext, req : RequestContext) -> ApiResponse {
  let route = parse_route(req.http_method, req.path)
  match route {
    ListGroupTickets(group_id) => handle_list_group_tickets(ctx, req, group_id)
    GetGroupChat(group_id) => handle_get_group_chat(ctx, req, group_id)
    GetGroupNotes(group_id) => handle_get_group_notes(ctx, req, group_id)
    CreateGroupNote(group_id) => handle_create_group_note(ctx, req, group_id)
    GetGroupTicket(group_id, ticket_id) =>
      handle_get_group_ticket(ctx, req, group_id, ticket_id)
    ReplyGroupTicket(group_id, ticket_id) =>
      handle_reply_group_ticket(ctx, req, group_id, ticket_id)
    ListTickets => handle_list_tickets(ctx, req)
    GetTicket(id) => handle_get_ticket(ctx, id)
    GetTimeline(id) => handle_get_timeline(ctx, id)
    GetWorkspaceItems(id) => handle_get_workspace_items(ctx, id)
    CreateNote(id) => handle_create_note(ctx, req, id)
    CreateDraft(id) => handle_create_draft(ctx, req, id)
    UpdateDraft(ticket_id, msg_id) =>
      handle_update_draft(ctx, req, ticket_id, msg_id)
    RecheckDraft(ticket_id, msg_id) =>
      handle_recheck_draft(ctx, req, ticket_id, msg_id)
    PublishDraft(ticket_id, msg_id) =>
      handle_publish_draft(ctx, req, ticket_id, msg_id)
    NotFound => ApiResponse::error(ApiError::NotFound("Endpoint not found"))
  }
}

/// =============================================================================
/// Log Helpers
/// =============================================================================

///|
fn record_log(ctx : AppContext, entry : @shared.LogEntry) -> Unit {
  match ctx.log_store {
    Some(store) => store.append_entry(entry)
    None => ()
  }
}

///|
fn message_entity_type(message : @shared.Message) -> String {
  if message.is_draft {
    "draft"
  } else if message.visibility == @shared.Internal {
    "note"
  } else {
    "message"
  }
}

///|
fn record_message_log(
  ctx : AppContext,
  event_type : String,
  message : @shared.Message,
  actor_id : String,
  payload_json : String,
  created_at : String,
) -> Unit {
  let entry : @shared.LogEntry = {
    log_id: (ctx.generate_id)(),
    ticket_id: message.ticket_id,
    event_type,
    entity_type: message_entity_type(message),
    entity_id: message.message_id,
    actor_id,
    payload_json,
    created_at,
  }
  record_log(ctx, entry)
}

/// =============================================================================
/// Group Authorization Helpers
/// =============================================================================

///|
fn authorize_group(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
  write? : Bool = false,
) -> ApiError? {
  if req.user_id == "" {
    return Some(ApiError::Unauthorized("Authentication required"))
  }
  if group_id == "" {
    return Some(ApiError::BadRequest("group_id is required"))
  }
  if !ctx.group_member_repo.is_group_member(group_id, req.user_id) {
    return Some(
      ApiError::Forbidden("User is not a member of group \{group_id}"),
    )
  }
  if write && !ctx.group_member_repo.can_post(group_id, req.user_id) {
    return Some(
      ApiError::Forbidden("User has no post permission in group \{group_id}"),
    )
  }
  None
}

///|
fn ensure_group_default_ticket(
  ctx : AppContext,
  group_id : String,
) -> @shared.Ticket {
  let tickets = ctx.ticket_repo.list_by_group(group_id)
  if !tickets.is_empty() {
    return tickets[0]
  }
  let ticket_id = "grp-\{group_id}-\{(ctx.generate_id)()}"
  let now = (ctx.current_timestamp)()
  let ticket = @shared.Ticket::{
    ..@shared.Ticket::new(
      ticket_id,
      "Group chat",
      @shared.ChatAMetadata::new("group", group_id, ""),
      group_id~,
    ),
    created_at: now,
    updated_at: now,
  }
  let _ = ctx.ticket_repo.create(ticket)
  ticket
}

/// =============================================================================
/// Group Handlers (Group-first API)
/// =============================================================================

///|
pub fn handle_list_group_tickets(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
) -> ApiResponse {
  match authorize_group(ctx, req, group_id) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }
  let status = if req.path.contains("status=open") {
    Some(@shared.TicketStatus::Open)
  } else if req.path.contains("status=closed") {
    Some(@shared.TicketStatus::Closed)
  } else if req.path.contains("status=pending") {
    Some(@shared.TicketStatus::Pending)
  } else {
    None
  }
  let tickets = match status {
    Some(s) => ctx.ticket_repo.list_by_group_and_status(group_id, s)
    None => ctx.ticket_repo.list_by_group(group_id)
  }
  ApiResponse::ok(tickets_to_json(tickets))
}

///|
pub fn handle_get_group_chat(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
) -> ApiResponse {
  match authorize_group(ctx, req, group_id) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }
  let messages = ctx.message_repo.list_public_by_group(group_id)
  ApiResponse::ok(messages_to_json(messages))
}

///|
pub fn handle_get_group_notes(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
) -> ApiResponse {
  match authorize_group(ctx, req, group_id) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }
  let messages = ctx.message_repo.list_internal_by_group(group_id)
  ApiResponse::ok(messages_to_json(messages))
}

///|
pub fn handle_create_group_note(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
) -> ApiResponse {
  match authorize_group(ctx, req, group_id, write=true) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }
  let text = extract_json_field(req.body, "text")
  if text == "" {
    return ApiResponse::error(ApiError::BadRequest("Note text is required"))
  }
  let ticket = ensure_group_default_ticket(ctx, group_id)
  let msg_id = (ctx.generate_id)()
  let timestamp = (ctx.current_timestamp)()
  let note = @shared.Message::{
    ..@shared.Message::new_note(
      msg_id,
      ticket.ticket_id,
      text,
      req.user_id,
      group_id~,
    ),
    timestamp,
  }
  match ctx.message_repo.create(note) {
    Ok(_) => {
      record_message_log(
        ctx,
        "group_note_created",
        note,
        req.user_id,
        message_to_json(note),
        note.timestamp,
      )
      ApiResponse::created(message_to_json(note))
    }
    Err(@core.DuplicateKey(msg)) => ApiResponse::error(ApiError::Conflict(msg))
    Err(_) =>
      ApiResponse::error(ApiError::InternalError("Failed to create group note"))
  }
}

///|
pub fn handle_get_group_ticket(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
  ticket_id : String,
) -> ApiResponse {
  match authorize_group(ctx, req, group_id) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }
  match ctx.ticket_repo.get(ticket_id) {
    Ok(ticket) =>
      if ticket.group_id != group_id {
        ApiResponse::error(ApiError::NotFound("Ticket not found in group"))
      } else {
        ApiResponse::ok(ticket_to_json(ticket))
      }
    Err(@core.NotFound(msg)) => ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      ApiResponse::error(ApiError::InternalError("Failed to get group ticket"))
  }
}

///|
pub fn handle_reply_group_ticket(
  ctx : AppContext,
  req : RequestContext,
  group_id : String,
  ticket_id : String,
) -> ApiResponse {
  match authorize_group(ctx, req, group_id, write=true) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }
  let ticket = match ctx.ticket_repo.get(ticket_id) {
    Ok(v) => v
    Err(@core.NotFound(msg)) =>
      return ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      return ApiResponse::error(
        ApiError::InternalError("Failed to get group ticket"),
      )
  }
  if ticket.group_id != group_id {
    return ApiResponse::error(ApiError::NotFound("Ticket not found in group"))
  }
  let text = extract_json_field(req.body, "text")
  if text == "" {
    return ApiResponse::error(ApiError::BadRequest("Reply text is required"))
  }
  let msg_id = (ctx.generate_id)()
  let timestamp = (ctx.current_timestamp)()
  let reply = @shared.Message::{
    ..@shared.Message::new(
      msg_id,
      ticket_id,
      text,
      @shared.Public,
      @shared.Console,
      req.user_id,
      group_id~,
    ),
    timestamp,
  }
  match ctx.message_repo.create(reply) {
    Ok(_) => {
      record_message_log(
        ctx,
        "group_ticket_replied",
        reply,
        req.user_id,
        message_to_json(reply),
        reply.timestamp,
      )
      ApiResponse::created(message_to_json(reply))
    }
    Err(@core.DuplicateKey(msg)) => ApiResponse::error(ApiError::Conflict(msg))
    Err(_) =>
      ApiResponse::error(
        ApiError::InternalError("Failed to create group ticket reply"),
      )
  }
}

/// =============================================================================
/// Ticket Handlers
/// =============================================================================

///|
/// GET /api/tickets - List tickets with optional status filter
pub fn handle_list_tickets(
  ctx : AppContext,
  req : RequestContext,
) -> ApiResponse {
  // Parse query params for status filter (simplified)
  let status = if req.path.contains("status=open") {
    Some(@shared.TicketStatus::Open)
  } else if req.path.contains("status=closed") {
    Some(@shared.TicketStatus::Closed)
  } else if req.path.contains("status=pending") {
    Some(@shared.TicketStatus::Pending)
  } else {
    None
  }
  let tickets = match status {
    Some(s) => ctx.ticket_repo.list_by_status(s)
    None => ctx.ticket_repo.list()
  }
  let json = tickets_to_json(tickets)
  ApiResponse::ok(json)
}

///|
/// GET /api/tickets/{id} - Get single ticket
pub fn handle_get_ticket(ctx : AppContext, ticket_id : String) -> ApiResponse {
  match ctx.ticket_repo.get(ticket_id) {
    Ok(ticket) => ApiResponse::ok(ticket_to_json(ticket))
    Err(@core.NotFound(msg)) => ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      ApiResponse::error(ApiError::InternalError("Failed to get ticket"))
  }
}

/// =============================================================================
/// Timeline Handlers
/// =============================================================================

///|
/// GET /api/tickets/{id}/timeline - Get public messages only
pub fn handle_get_timeline(ctx : AppContext, ticket_id : String) -> ApiResponse {
  // Verify ticket exists
  match ctx.ticket_repo.get(ticket_id) {
    Err(@core.NotFound(msg)) =>
      return ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get ticket"))
    Ok(_) => ()
  }
  let messages = ctx.message_repo.list_public_by_ticket(ticket_id)
  let json = messages_to_json(messages)
  ApiResponse::ok(json)
}

/// =============================================================================
/// Workspace Handlers
/// =============================================================================

///|
/// GET /api/tickets/{id}/items - Get all messages (internal + public)
pub fn handle_get_workspace_items(
  ctx : AppContext,
  ticket_id : String,
) -> ApiResponse {
  // Verify ticket exists
  match ctx.ticket_repo.get(ticket_id) {
    Err(@core.NotFound(msg)) =>
      return ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get ticket"))
    Ok(_) => ()
  }
  let messages = ctx.message_repo.list_workspace_by_ticket(ticket_id)
  let json = messages_to_json(messages)
  ApiResponse::ok(json)
}

///|
/// POST /api/tickets/{id}/notes - Create internal note
pub fn handle_create_note(
  ctx : AppContext,
  req : RequestContext,
  ticket_id : String,
) -> ApiResponse {
  // Verify ticket exists
  let ticket = match ctx.ticket_repo.get(ticket_id) {
    Err(@core.NotFound(msg)) =>
      return ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get ticket"))
    Ok(t) => t
  }

  // Parse request body (simplified - in real impl use JSON parser)
  let text = extract_json_field(req.body, "text")
  if text == "" {
    return ApiResponse::error(ApiError::BadRequest("Note text is required"))
  }

  // Create note message
  let msg_id = (ctx.generate_id)()
  let timestamp = (ctx.current_timestamp)()
  let note = @shared.Message::{
    ..@shared.Message::new_note(
      msg_id,
      ticket_id,
      text,
      req.user_id,
      group_id=ticket.group_id,
    ),
    timestamp,
  }

  // Save to repository
  match ctx.message_repo.create(note) {
    Ok(_) => {
      record_message_log(
        ctx,
        "note_created",
        note,
        req.user_id,
        message_to_json(note),
        note.timestamp,
      )
      ApiResponse::created(message_to_json(note))
    }
    Err(@core.DuplicateKey(msg)) => ApiResponse::error(ApiError::Conflict(msg))
    Err(_) =>
      ApiResponse::error(ApiError::InternalError("Failed to create note"))
  }
}

///|
/// POST /api/tickets/{id}/drafts - Create draft
pub fn handle_create_draft(
  ctx : AppContext,
  req : RequestContext,
  ticket_id : String,
) -> ApiResponse {
  // Verify ticket exists
  let ticket = match ctx.ticket_repo.get(ticket_id) {
    Err(@core.NotFound(msg)) =>
      return ApiResponse::error(ApiError::NotFound(msg))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get ticket"))
    Ok(t) => t
  }

  // Parse request body
  let text = extract_json_field(req.body, "text")
  let idempotency_key = extract_json_field(req.body, "idempotency_key")
  if text == "" {
    return ApiResponse::error(ApiError::BadRequest("Draft text is required"))
  }
  if idempotency_key == "" {
    return ApiResponse::error(
      ApiError::BadRequest("Idempotency key is required"),
    )
  }

  // Check idempotency - return existing if already created
  match ctx.message_repo.get_by_idempotency_key(idempotency_key) {
    Some(existing) => return ApiResponse::ok(message_to_json(existing))
    None => ()
  }

  // Create draft message
  let msg_id = (ctx.generate_id)()
  let timestamp = (ctx.current_timestamp)()
  let draft = @shared.Message::{
    ..@shared.Message::new_draft(
      msg_id,
      ticket_id,
      text,
      req.user_id,
      idempotency_key,
      group_id=ticket.group_id,
    ),
    timestamp,
  }

  // Save to repository
  match ctx.message_repo.create(draft) {
    Ok(_) => {
      record_message_log(
        ctx,
        "draft_created",
        draft,
        req.user_id,
        message_to_json(draft),
        draft.timestamp,
      )
      ApiResponse::created(message_to_json(draft))
    }
    Err(@core.DuplicateKey(msg)) => ApiResponse::error(ApiError::Conflict(msg))
    Err(_) =>
      ApiResponse::error(ApiError::InternalError("Failed to create draft"))
  }
}

///|
/// PUT /api/tickets/{id}/drafts/{msgId} - Update draft
pub fn handle_update_draft(
  ctx : AppContext,
  req : RequestContext,
  ticket_id : String,
  msg_id : String,
) -> ApiResponse {
  // Get existing draft
  let draft = match ctx.message_repo.get(msg_id) {
    Ok(msg) => msg
    Err(@core.NotFound(_)) =>
      return ApiResponse::error(ApiError::NotFound("Draft not found"))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get draft"))
  }

  // Verify draft belongs to ticket
  if draft.ticket_id != ticket_id {
    return ApiResponse::error(
      ApiError::NotFound("Draft not found in this ticket"),
    )
  }

  // Verify it's actually a draft
  if not(draft.is_draft) {
    return ApiResponse::error(
      ApiError::BadRequest("Cannot update non-draft message"),
    )
  }

  // Check if draft can be edited
  if not(@core.can_edit(draft.draft_status)) {
    return ApiResponse::error(
      ApiError::BadRequest(
        "Cannot edit draft in current state: \{draft.draft_status.to_string()}",
      ),
    )
  }

  // Parse request body
  let text = extract_json_field(req.body, "text")
  if text == "" {
    return ApiResponse::error(ApiError::BadRequest("Draft text is required"))
  }

  // Update draft - reset to pending for recheck
  let updated = @shared.Message::{
    ..draft,
    text,
    draft_status: @shared.DraftStatus::Pending,
    ai_check_result: None,
  }
  match ctx.message_repo.update(updated) {
    Ok(_) => {
      record_message_log(
        ctx,
        "draft_updated",
        updated,
        req.user_id,
        message_to_json(updated),
        (ctx.current_timestamp)(),
      )
      ApiResponse::ok(message_to_json(updated))
    }
    Err(_) =>
      ApiResponse::error(ApiError::InternalError("Failed to update draft"))
  }
}

///|
/// POST /api/tickets/{id}/drafts/{msgId}/recheck - Trigger AI recheck
pub fn handle_recheck_draft(
  ctx : AppContext,
  req : RequestContext,
  ticket_id : String,
  msg_id : String,
) -> ApiResponse {
  // Get existing draft
  let draft = match ctx.message_repo.get(msg_id) {
    Ok(msg) => msg
    Err(@core.NotFound(_)) =>
      return ApiResponse::error(ApiError::NotFound("Draft not found"))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get draft"))
  }

  // Verify draft belongs to ticket
  if draft.ticket_id != ticket_id {
    return ApiResponse::error(
      ApiError::NotFound("Draft not found in this ticket"),
    )
  }

  // Start check using state machine
  match @core.start_check(draft) {
    Ok(checking) =>
      match ctx.message_repo.update(checking) {
        Ok(_) => {
          record_message_log(
            ctx,
            "draft_recheck_requested",
            checking,
            req.user_id,
            message_to_json(checking),
            (ctx.current_timestamp)(),
          )
          ApiResponse::ok(message_to_json(checking))
        }
        Err(_) =>
          ApiResponse::error(ApiError::InternalError("Failed to update draft"))
      }
    Err(@core.InvalidTransition(msg)) =>
      ApiResponse::error(ApiError::BadRequest(msg))
    Err(_) =>
      ApiResponse::error(
        ApiError::BadRequest("Cannot recheck draft in current state"),
      )
  }
}

///|
/// POST /api/tickets/{id}/drafts/{msgId}/publish - Publish draft
pub fn handle_publish_draft(
  ctx : AppContext,
  req : RequestContext,
  ticket_id : String,
  msg_id : String,
) -> ApiResponse {
  // Get existing draft
  let draft = match ctx.message_repo.get(msg_id) {
    Ok(msg) => msg
    Err(@core.NotFound(_)) =>
      return ApiResponse::error(ApiError::NotFound("Draft not found"))
    Err(_) =>
      return ApiResponse::error(ApiError::InternalError("Failed to get draft"))
  }

  // Verify draft belongs to ticket
  if draft.ticket_id != ticket_id {
    return ApiResponse::error(
      ApiError::NotFound("Draft not found in this ticket"),
    )
  }

  // Parse idempotency key
  let idempotency_key = if req.idempotency_key != "" {
    req.idempotency_key
  } else {
    extract_json_field(req.body, "idempotency_key")
  }
  if idempotency_key == "" {
    return ApiResponse::error(
      ApiError::BadRequest("Idempotency key is required for publish"),
    )
  }

  // Server-side validation (CRITICAL - don't trust client)
  match validate_publish_request(draft) {
    Some(err) => return ApiResponse::error(err)
    None => ()
  }

  // Publish using state machine
  let timestamp = (ctx.current_timestamp)()
  match @core.publish_draft(draft, timestamp) {
    Ok(published) =>
      match ctx.message_repo.update(published) {
        Ok(_) => {
          record_message_log(
            ctx,
            "draft_published",
            published,
            req.user_id,
            message_to_json(published),
            timestamp,
          )
          ApiResponse::ok(message_to_json(published))
        }
        Err(_) =>
          ApiResponse::error(ApiError::InternalError("Failed to publish draft"))
      }
    Err(@core.AlreadyPublished) =>
      ApiResponse::error(ApiError::Conflict("Draft has already been published"))
    Err(@core.NotChecked) =>
      ApiResponse::error(
        ApiError::BadRequest("Draft must be checked before publishing"),
      )
    Err(_) =>
      ApiResponse::error(
        ApiError::BadRequest("Cannot publish draft in current state"),
      )
  }
}

/// =============================================================================
/// JSON Serialization Helpers
/// =============================================================================

///|
/// Convert ticket to JSON string
pub fn ticket_to_json(ticket : @shared.Ticket) -> String {
  "{\"ticket_id\":\"\{ticket.ticket_id}\",\"group_id\":\"\{ticket.group_id}\",\"status\":\"\{ticket.status.to_string()}\",\"subject\":\"\{escape_json_string(ticket.subject)}\",\"chat_a\":{\"platform\":\"\{escape_json_string(ticket.chat_a.platform)}\",\"dm_id\":\"\{escape_json_string(ticket.chat_a.dm_id)}\",\"bot_account_id\":\"\{escape_json_string(ticket.chat_a.bot_account_id)}\",\"last_inbound_cursor\":\"\{escape_json_string(ticket.chat_a.last_inbound_cursor)}\"},\"assignees\":[\{array_to_json_strings(ticket.assignees)}],\"lock_version\":\{ticket.lock_version.to_string()},\"created_at\":\"\{ticket.created_at}\",\"updated_at\":\"\{ticket.updated_at}\"}"
}

///|
/// Convert tickets array to JSON
pub fn tickets_to_json(tickets : Array[@shared.Ticket]) -> String {
  let items = tickets.map(ticket_to_json)
  "[" +
  items.fold(init="", fn(acc, item) {
    if acc == "" {
      item
    } else {
      acc + "," + item
    }
  }) +
  "]"
}

///|
/// Convert message to JSON string
pub fn message_to_json(msg : @shared.Message) -> String {
  let ai_check = match msg.ai_check_result {
    Some(r) =>
      "{\"passed\":\{r.passed.to_string()},\"warnings\":[\{array_to_json_strings(r.warnings)}],\"suggestions\":[\{array_to_json_strings(r.suggestions)}]}"
    None => "null"
  }
  "{\"message_id\":\"\{msg.message_id}\",\"ticket_id\":\"\{msg.ticket_id}\",\"group_id\":\"\{msg.group_id}\",\"text\":\"\{escape_json_string(msg.text)}\",\"attachments\":[\{attachments_to_json(msg.attachments)}],\"reply_to_message_id\":\"\{escape_json_string(msg.reply_to_message_id)}\",\"visibility\":\"\{msg.visibility.to_string()}\",\"origin\":\"\{msg.origin.to_string()}\",\"is_draft\":\{msg.is_draft.to_string()},\"draft_status\":\"\{msg.draft_status.to_string()}\",\"ai_check_result\":\{ai_check},\"idempotency_key\":\"\{escape_json_string(msg.idempotency_key)}\",\"sender_id\":\"\{msg.sender_id}\",\"sender_name\":\"\{escape_json_string(msg.sender_name)}\",\"timestamp\":\"\{msg.timestamp}\",\"published_at\":\"\{msg.published_at}\"}"
}

///|
/// Convert messages array to JSON
pub fn messages_to_json(messages : Array[@shared.Message]) -> String {
  let items = messages.map(message_to_json)
  "[" +
  items.fold(init="", fn(acc, item) {
    if acc == "" {
      item
    } else {
      acc + "," + item
    }
  }) +
  "]"
}

///|
/// Convert string array to JSON array of strings
fn array_to_json_strings(arr : Array[String]) -> String {
  arr
  .map(fn(s) { "\"\{escape_json_string(s)}\"" })
  .fold(init="", fn(acc, item) {
    if acc == "" {
      item
    } else {
      acc + "," + item
    }
  })
}

///|
fn attachment_to_json(att : @shared.Attachment) -> String {
  "{\"type\":\"\{att.attachment_type.to_string()}\",\"url\":\"\{escape_json_string(att.url)}\",\"name\":\"\{escape_json_string(att.name)}\"}"
}

///|
fn attachments_to_json(arr : Array[@shared.Attachment]) -> String {
  arr.map(attachment_to_json).join(",")
}

///|
/// Escape special characters in JSON string
fn escape_json_string(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => result = result + c.to_string()
    }
  }
  result
}

///|
/// Extract field from JSON (simplified parser)
fn extract_json_field(json : String, field : String) -> String {
  let key = "\"" + field + "\":"
  let start_idx = find_substring(json, key)
  if start_idx < 0 {
    return ""
  }
  let value_start = start_idx + key.length()

  // Skip whitespace
  let mut i = value_start
  while i < json.length() && (json[i] == ' ' || json[i] == '\t') {
    i = i + 1
  }
  if i >= json.length() {
    return ""
  }

  // Check if string value
  if json[i] == '"' {
    // Extract string value
    let mut result = ""
    i = i + 1
    while i < json.length() && json[i] != '"' {
      if json[i] == '\\' && i + 1 < json.length() {
        i = i + 1
        match json[i] {
          'n' => result = result + "\n"
          'r' => result = result + "\r"
          't' => result = result + "\t"
          '"' => result = result + "\""
          '\\' => result = result + "\\"
          _ => result = result + json[i].to_string()
        }
      } else {
        result = result + json[i].to_string()
      }
      i = i + 1
    }
    return result
  }
  ""
}

///|
/// Find substring in string (returns -1 if not found)
fn find_substring(haystack : String, needle : String) -> Int {
  if needle.length() == 0 {
    return 0
  }
  if needle.length() > haystack.length() {
    return -1
  }
  for i = 0; i <= haystack.length() - needle.length(); i = i + 1 {
    let mut matches = true
    for j = 0; j < needle.length(); j = j + 1 {
      if haystack[i + j] != needle[j] {
        matches = false
        break
      }
    }
    if matches {
      return i
    }
  }
  -1
}
