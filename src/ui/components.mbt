///|
/// UI Components for the 3-pane layout
/// These components define the structure that will be rendered via Luna.mbt

/// =============================================================================
/// Pane 1: Ticket Inbox Component
/// =============================================================================

///|
/// Ticket list item view data
pub(all) struct TicketListItem {
  ticket_id : String
  subject : String
  user_name : String
  elapsed_time : String // e.g., "5m", "2h", "1d"
  assignee_names : Array[String]
  has_draft : Bool // Show draft badge
  draft_status : String // "pending", "checking", "checked", "rejected"
  is_selected : Bool
} derive(Show, Eq)

///|
/// Create TicketListItem from Ticket and Messages
pub fn TicketListItem::from_ticket(
  ticket : @shared.Ticket,
  draft_status : String,
  has_draft : Bool,
  is_selected : Bool,
  user_name : String,
  elapsed_time : String,
) -> TicketListItem {
  {
    ticket_id: ticket.ticket_id,
    subject: ticket.subject,
    user_name,
    elapsed_time,
    assignee_names: ticket.assignees,
    has_draft,
    draft_status,
    is_selected,
  }
}

///|
/// Inbox pane state
pub(all) struct InboxPaneState {
  tickets : Array[TicketListItem]
  filter_status : @shared.TicketStatus
  is_loading : Bool
} derive(Show, Eq)

///|
/// Create initial inbox state
pub fn InboxPaneState::initial() -> InboxPaneState {
  { tickets: [], filter_status: @shared.TicketStatus::Open, is_loading: false }
}

/// =============================================================================
/// Pane 2: Public Timeline Component
/// =============================================================================

///|
/// Timeline message view data
pub(all) struct TimelineMessage {
  message_id : String
  text : String
  sender_name : String
  timestamp : String
  is_from_user : Bool // true = user message, false = support reply
  attachments : Array[AttachmentView]
  reply_thread_id : String // For threading visualization
} derive(Show, Eq)

///|
/// Attachment display data
pub(all) struct AttachmentView {
  name : String
  url : String
  attachment_type : String // "image", "file", "video", "audio"
  thumbnail_url : String // For image preview (empty if N/A)
} derive(Show, Eq)

///|
/// Create AttachmentView from Attachment
pub fn AttachmentView::from_attachment(
  att : @shared.Attachment,
) -> AttachmentView {
  {
    name: att.name,
    url: att.url,
    attachment_type: att.attachment_type.to_string(),
    thumbnail_url: if att.attachment_type == @shared.AttachmentType::Image {
      att.url
    } else {
      ""
    },
  }
}

///|
/// Timeline pane state
pub(all) struct TimelinePaneState {
  messages : Array[TimelineMessage]
  ticket_subject : String
  is_loading : Bool
} derive(Show, Eq)

///|
/// Create initial timeline state
pub fn TimelinePaneState::initial() -> TimelinePaneState {
  { messages: [], ticket_subject: "", is_loading: false }
}

///|
/// Create TimelineMessage from Message
pub fn TimelineMessage::from_message(
  msg : @shared.Message,
  sender_name : String,
) -> TimelineMessage {
  {
    message_id: msg.message_id,
    text: msg.text,
    sender_name,
    timestamp: msg.timestamp,
    is_from_user: msg.origin == @shared.Origin::ChatA,
    attachments: msg.attachments.map(AttachmentView::from_attachment),
    reply_thread_id: msg.reply_to_message_id,
  }
}

/// =============================================================================
/// Pane 3: Workspace Component
/// =============================================================================

///|
/// Workspace item - can be internal note or draft
pub(all) struct WorkspaceItem {
  message_id : String
  text : String
  sender_name : String
  timestamp : String
  is_draft : Bool
  draft_status : String // "pending", "checking", "checked", "rejected", "published"
  ai_warnings : Array[String]
  ai_suggestions : Array[String]
  can_publish : Bool
  can_edit : Bool
} derive(Show, Eq)

///|
/// Create WorkspaceItem from Message
pub fn WorkspaceItem::from_message(
  msg : @shared.Message,
  sender_name : String,
) -> WorkspaceItem {
  let (warnings, suggestions) = match msg.ai_check_result {
    Some(result) => (result.warnings, result.suggestions)
    None => ([], [])
  }
  {
    message_id: msg.message_id,
    text: msg.text,
    sender_name,
    timestamp: msg.timestamp,
    is_draft: msg.is_draft,
    draft_status: msg.draft_status.to_string(),
    ai_warnings: warnings,
    ai_suggestions: suggestions,
    can_publish: @core.can_publish(msg.draft_status),
    can_edit: @core.can_edit(msg.draft_status),
  }
}

///|
/// Review panel showing AI check results
pub(all) struct ReviewPanelState {
  is_visible : Bool
  draft_id : String
  status : String // "pending", "checking", "checked", "rejected"
  warnings : Array[String]
  suggestions : Array[String]
  check_passed : Bool
} derive(Show, Eq)

///|
/// Create empty review panel state
pub fn ReviewPanelState::empty() -> ReviewPanelState {
  {
    is_visible: false,
    draft_id: "",
    status: "",
    warnings: [],
    suggestions: [],
    check_passed: false,
  }
}

///|
/// Create review panel state from Message
pub fn ReviewPanelState::from_draft(msg : @shared.Message) -> ReviewPanelState {
  match msg.ai_check_result {
    Some(result) =>
      {
        is_visible: true,
        draft_id: msg.message_id,
        status: msg.draft_status.to_string(),
        warnings: result.warnings,
        suggestions: result.suggestions,
        check_passed: result.passed,
      }
    None =>
      {
        is_visible: msg.is_draft &&
        msg.draft_status != @shared.DraftStatus::Pending,
        draft_id: msg.message_id,
        status: msg.draft_status.to_string(),
        warnings: [],
        suggestions: [],
        check_passed: false,
      }
  }
}

///|
/// Workspace pane state
pub(all) struct WorkspacePaneState {
  items : Array[WorkspaceItem]
  current_draft : WorkspaceItem?
  review_panel : ReviewPanelState
  editor_mode : EditorMode
  editor_text : String
  is_submitting : Bool
} derive(Show, Eq)

///|
/// Create initial workspace state
pub fn WorkspacePaneState::initial() -> WorkspacePaneState {
  {
    items: [],
    current_draft: None,
    review_panel: ReviewPanelState::empty(),
    editor_mode: Note,
    editor_text: "",
    is_submitting: false,
  }
}

/// =============================================================================
/// Publish Confirmation Modal
/// =============================================================================

///|
/// Publish modal state
pub(all) struct PublishModalState {
  is_visible : Bool
  draft_id : String
  draft_preview : String // First 100 chars of draft
  target_channel : String // e.g., "Slack DM to @user123"
  idempotency_key : String
} derive(Show, Eq)

///|
/// Create hidden modal state
pub fn PublishModalState::hidden() -> PublishModalState {
  {
    is_visible: false,
    draft_id: "",
    draft_preview: "",
    target_channel: "",
    idempotency_key: "",
  }
}

///|
/// Create visible modal state
pub fn PublishModalState::show(
  draft : @shared.Message,
  target_channel : String,
  idempotency_key : String,
) -> PublishModalState {
  let preview = if draft.text.length() > 100 {
    let mut result = ""
    for i = 0; i < 100 && i < draft.text.length(); i = i + 1 {
      result = result + draft.text[i].to_string()
    }
    result + "..."
  } else {
    draft.text
  }
  {
    is_visible: true,
    draft_id: draft.message_id,
    draft_preview: preview,
    target_channel,
    idempotency_key,
  }
}

/// =============================================================================
/// Full Application View State
/// =============================================================================

///|
/// Complete application view state
pub(all) struct AppViewState {
  layout : LayoutConfig
  inbox : InboxPaneState
  timeline : TimelinePaneState
  workspace : WorkspacePaneState
  publish_modal : PublishModalState
  selected_ticket_id : String
  error_message : String
  is_connected : Bool // WebSocket connection status
} derive(Show, Eq)

///|
/// Create initial application view state
pub fn AppViewState::initial() -> AppViewState {
  {
    layout: LayoutConfig::default(),
    inbox: InboxPaneState::initial(),
    timeline: TimelinePaneState::initial(),
    workspace: WorkspacePaneState::initial(),
    publish_modal: PublishModalState::hidden(),
    selected_ticket_id: "",
    error_message: "",
    is_connected: false,
  }
}
