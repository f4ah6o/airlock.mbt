///|
/// Ticket status enum
pub(all) enum TicketStatus {
  Open
  Closed
  Pending
} derive(Show, Eq)

///|
/// Convert TicketStatus to string
pub fn TicketStatus::to_string(self : TicketStatus) -> String {
  match self {
    Open => "open"
    Closed => "closed"
    Pending => "pending"
  }
}

///|
/// Message visibility enum
pub(all) enum Visibility {
  Public // Shown in Pane 2 (Timeline)
  Internal // Shown only in Pane 3 (Workspace)
} derive(Show, Eq)

///|
pub fn Visibility::to_string(self : Visibility) -> String {
  match self {
    Public => "public"
    Internal => "internal"
  }
}

///|
/// Message origin enum
pub(all) enum Origin {
  ChatA // From user via external chat platform
  Console // From support staff via Chat B console
  System // From system/bot
} derive(Show, Eq)

///|
pub fn Origin::to_string(self : Origin) -> String {
  match self {
    ChatA => "chatA"
    Console => "console"
    System => "system"
  }
}

///|
/// Draft status state machine states
pub(all) enum DraftStatus {
  Pending // Draft created, awaiting check
  Checking // AI check in progress
  Checked // AI check passed, ready to publish
  Rejected // AI check failed, needs revision
  Published // Draft has been published to Chat A
} derive(Show, Eq)

///|
pub fn DraftStatus::to_string(self : DraftStatus) -> String {
  match self {
    Pending => "pending"
    Checking => "checking"
    Checked => "checked"
    Rejected => "rejected"
    Published => "published"
  }
}

///|
/// Attachment type enum
pub(all) enum AttachmentType {
  Image
  File
  Video
  Audio
} derive(Show, Eq)

///|
pub fn AttachmentType::to_string(self : AttachmentType) -> String {
  match self {
    Image => "image"
    File => "file"
    Video => "video"
    Audio => "audio"
  }
}

///|
/// Attachment data structure
pub(all) struct Attachment {
  attachment_type : AttachmentType
  url : String
  name : String
} derive(Show, Eq)

///|
/// Create a new Attachment
pub fn Attachment::new(
  attachment_type : AttachmentType,
  url : String,
  name : String,
) -> Attachment {
  { attachment_type, url, name }
}

///|
/// Chat A platform metadata
pub(all) struct ChatAMetadata {
  platform : String // e.g., "slack", "discord", "direct"
  dm_id : String // Channel/DM ID for sending
  last_inbound_cursor : String // Cursor for webhook recovery
} derive(Show, Eq)

///|
/// Create new ChatAMetadata
pub fn ChatAMetadata::new(
  platform : String,
  dm_id : String,
  last_inbound_cursor : String,
) -> ChatAMetadata {
  { platform, dm_id, last_inbound_cursor }
}

///|
/// Normalized inbound message from external chat platforms.
pub(all) struct InboundMessage {
  external_id : String
  platform : String
  channel_id : String
  sender_id : String
  sender_name : String
  text : String
  attachments : Array[Attachment]
  timestamp : String
  reply_to_id : String
  raw_data : String
} derive(Show, Eq)

///|
/// Create a new InboundMessage.
pub fn InboundMessage::new(
  external_id : String,
  platform : String,
  channel_id : String,
  sender_id : String,
  sender_name : String,
  text : String,
  timestamp : String,
) -> InboundMessage {
  {
    external_id,
    platform,
    channel_id,
    sender_id,
    sender_name,
    text,
    attachments: [],
    timestamp,
    reply_to_id: "",
    raw_data: "",
  }
}

///|
/// AI check result structure
pub(all) struct AICheckResult {
  passed : Bool
  warnings : Array[String]
  suggestions : Array[String]
} derive(Show, Eq)

///|
/// Create a new AICheckResult
pub fn AICheckResult::new(
  passed : Bool,
  warnings : Array[String],
  suggestions : Array[String],
) -> AICheckResult {
  { passed, warnings, suggestions }
}

///|
/// Create a passing AICheckResult
pub fn AICheckResult::pass() -> AICheckResult {
  { passed: true, warnings: [], suggestions: [] }
}

///|
/// Create a failing AICheckResult
pub fn AICheckResult::fail(warnings : Array[String]) -> AICheckResult {
  { passed: false, warnings, suggestions: [] }
}

///|
/// Ticket data structure (Session)
pub(all) struct Ticket {
  ticket_id : String
  status : TicketStatus
  subject : String

  // External platform metadata (for Adapter)
  chat_a : ChatAMetadata

  // Operation management data
  assignees : Array[String] // Assigned staff IDs
  last_public_at : String // Last response timestamp (for SLA)
  lock_version : Int // Optimistic locking version

  // Timestamps
  created_at : String
  updated_at : String
} derive(Show, Eq)

///|
/// Create a new Ticket
pub fn Ticket::new(
  ticket_id : String,
  subject : String,
  chat_a : ChatAMetadata,
) -> Ticket {
  {
    ticket_id,
    status: Open,
    subject,
    chat_a,
    assignees: [],
    last_public_at: "",
    lock_version: 1,
    created_at: "",
    updated_at: "",
  }
}

///|
/// Message data structure
pub(all) struct Message {
  message_id : String
  ticket_id : String

  // Content
  text : String
  attachments : Array[Attachment]
  reply_to_message_id : String // For threading (empty if not a reply)

  // Control flags
  visibility : Visibility
  origin : Origin

  // Draft management (only valid when visibility is Internal)
  is_draft : Bool
  draft_status : DraftStatus
  ai_check_result : AICheckResult?

  // Idempotency management
  idempotency_key : String
  published_at : String // Timestamp when published (empty if not published)

  // Metadata
  sender_id : String
  timestamp : String
} derive(Show, Eq)

///|
/// Create a new Message
pub fn Message::new(
  message_id : String,
  ticket_id : String,
  text : String,
  visibility : Visibility,
  origin : Origin,
  sender_id : String,
) -> Message {
  {
    message_id,
    ticket_id,
    text,
    attachments: [],
    reply_to_message_id: "",
    visibility,
    origin,
    is_draft: false,
    draft_status: Pending,
    ai_check_result: None,
    idempotency_key: "",
    published_at: "",
    sender_id,
    timestamp: "",
  }
}

///|
/// Create a new draft message
pub fn Message::new_draft(
  message_id : String,
  ticket_id : String,
  text : String,
  sender_id : String,
  idempotency_key : String,
) -> Message {
  {
    message_id,
    ticket_id,
    text,
    attachments: [],
    reply_to_message_id: "",
    visibility: Internal,
    origin: Console,
    is_draft: true,
    draft_status: Pending,
    ai_check_result: None,
    idempotency_key,
    published_at: "",
    sender_id,
    timestamp: "",
  }
}

///|
/// Create a new internal note (non-draft)
pub fn Message::new_note(
  message_id : String,
  ticket_id : String,
  text : String,
  sender_id : String,
) -> Message {
  {
    message_id,
    ticket_id,
    text,
    attachments: [],
    reply_to_message_id: "",
    visibility: Internal,
    origin: Console,
    is_draft: false,
    draft_status: Pending, // Not used for notes
    ai_check_result: None,
    idempotency_key: "",
    published_at: "",
    sender_id,
    timestamp: "",
  }
}

///|
/// User/Admin identity structure
pub(all) struct User {
  user_id : String
  name : String
  email : String
  is_admin : Bool
} derive(Show, Eq)

///|
/// Create a new User
pub fn User::new(user_id : String, name : String, email : String) -> User {
  { user_id, name, email, is_admin: false }
}

///|
/// Create a new Admin user
pub fn User::new_admin(user_id : String, name : String, email : String) -> User {
  { user_id, name, email, is_admin: true }
}
