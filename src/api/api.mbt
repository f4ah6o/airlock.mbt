///|
/// API module for HTTP endpoint handlers
///
/// Endpoints to implement:
/// - GET /api/tickets?status=open - Fetch inbox
/// - GET /api/tickets/{id} - Get ticket details
/// - GET /api/tickets/{id}/timeline - Public messages only
/// - GET /api/tickets/{id}/items - All messages (workspace)
/// - POST /api/tickets/{id}/notes - Create internal note
/// - POST /api/tickets/{id}/drafts - Create draft
/// - PUT /api/tickets/{id}/drafts/{msgId} - Update draft
/// - POST /api/tickets/{id}/drafts/{msgId}/recheck - Trigger AI recheck
/// - POST /api/tickets/{id}/drafts/{msgId}/publish - Publish draft

///|
/// HTTP Method enum
pub(all) enum HttpMethod {
  Get
  Post
  Put
  Delete
} derive(Show, Eq)

///|
/// API error types
pub(all) enum ApiError {
  NotFound(String)
  BadRequest(String)
  Unauthorized(String)
  Forbidden(String)
  Conflict(String)
  InternalError(String)
} derive(Show, Eq)

///|
/// Get HTTP status code for API error
pub fn ApiError::status_code(self : ApiError) -> Int {
  match self {
    NotFound(_) => 404
    BadRequest(_) => 400
    Unauthorized(_) => 401
    Forbidden(_) => 403
    Conflict(_) => 409
    InternalError(_) => 500
  }
}

///|
/// API request context
pub(all) struct RequestContext {
  http_method : HttpMethod
  path : String
  body : String // JSON body
  user_id : String // Authenticated user ID
  idempotency_key : String // For POST/PUT requests
} derive(Show, Eq)

///|
/// Create a new RequestContext
pub fn RequestContext::new(
  http_method : HttpMethod,
  path : String,
  body : String,
  user_id : String,
) -> RequestContext {
  { http_method, path, body, user_id, idempotency_key: "" }
}

///|
/// API response
pub(all) struct ApiResponse {
  status_code : Int
  body : String
  content_type : String
} derive(Show, Eq)

///|
/// Create a successful JSON response
pub fn ApiResponse::json(status_code : Int, body : String) -> ApiResponse {
  { status_code, body, content_type: "application/json" }
}

///|
/// Create an error response
pub fn ApiResponse::error(err : ApiError) -> ApiResponse {
  let body = match err {
    NotFound(msg) => "{\"error\": \"not_found\", \"message\": \"\{msg}\"}"
    BadRequest(msg) => "{\"error\": \"bad_request\", \"message\": \"\{msg}\"}"
    Unauthorized(msg) =>
      "{\"error\": \"unauthorized\", \"message\": \"\{msg}\"}"
    Forbidden(msg) => "{\"error\": \"forbidden\", \"message\": \"\{msg}\"}"
    Conflict(msg) => "{\"error\": \"conflict\", \"message\": \"\{msg}\"}"
    InternalError(msg) =>
      "{\"error\": \"internal_error\", \"message\": \"\{msg}\"}"
  }
  { status_code: err.status_code(), body, content_type: "application/json" }
}

///|
/// Create a 200 OK response
pub fn ApiResponse::ok(body : String) -> ApiResponse {
  ApiResponse::json(200, body)
}

///|
/// Create a 201 Created response
pub fn ApiResponse::created(body : String) -> ApiResponse {
  ApiResponse::json(201, body)
}

///|
/// Create a 204 No Content response
pub fn ApiResponse::no_content() -> ApiResponse {
  { status_code: 204, body: "", content_type: "" }
}

///|
/// Publish request payload
pub(all) struct PublishRequest {
  idempotency_key : String
} derive(Show, Eq)

///|
/// Validate publish request
/// Returns ApiError if validation fails
pub fn validate_publish_request(message : @shared.Message) -> ApiError? {
  // Must be a draft
  if not(message.is_draft) {
    return Some(BadRequest("Cannot publish non-draft message"))
  }
  // Must be in checked state
  if message.draft_status != @shared.Checked {
    return Some(
      BadRequest(
        "Draft must be checked before publishing. Current status: \{message.draft_status.to_string()}",
      ),
    )
  }
  // Must not be already published
  if message.published_at != "" {
    return Some(Conflict("Draft has already been published"))
  }
  None
}

///|
/// Draft create/update request payload
pub(all) struct DraftRequest {
  text : String
  attachments : Array[@shared.Attachment]
  reply_to_message_id : String
  idempotency_key : String
} derive(Show, Eq)

///|
/// Note create request payload
pub(all) struct NoteRequest {
  text : String
  attachments : Array[@shared.Attachment]
} derive(Show, Eq)
