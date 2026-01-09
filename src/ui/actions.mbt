///|
/// UI Actions - Events that can be triggered from the UI
/// These actions will be dispatched to update application state

/// =============================================================================
/// Action Types
/// =============================================================================

///|
/// All possible UI actions
pub(all) enum UIAction {
  // Inbox actions
  SelectTicket(String)              // ticket_id
  FilterTickets(@shared.TicketStatus)
  RefreshInbox

  // Timeline actions (read-only, no direct input)
  ScrollToMessage(String)           // message_id

  // Workspace actions
  SetEditorMode(EditorMode)
  UpdateEditorText(String)
  SubmitNote                        // Submit internal note
  SubmitDraft                       // Submit draft for AI check
  EditDraft(String)                 // Edit existing draft (message_id)
  RequestRecheck(String)            // Recheck draft (message_id)
  ShowPublishConfirm(String)        // Show publish modal (message_id)
  HidePublishConfirm
  ConfirmPublish(String, String)    // Confirm publish (message_id, idempotency_key)

  // Global actions
  DismissError
  SetConnectionStatus(Bool)
} derive(Show, Eq)

/// =============================================================================
/// Action Results
/// =============================================================================

///|
/// Result of processing an action
pub(all) enum ActionResult {
  Success
  ValidationError(String)
  NetworkError(String)
  StateError(String)
} derive(Show, Eq)

///|
/// Check if action result is success
pub fn ActionResult::is_success(self : ActionResult) -> Bool {
  self == Success
}

///|
/// Get error message if any
pub fn ActionResult::error_message(self : ActionResult) -> String {
  match self {
    Success => ""
    ValidationError(msg) => msg
    NetworkError(msg) => msg
    StateError(msg) => msg
  }
}

/// =============================================================================
/// Action Validators
/// =============================================================================

///|
/// Validate submit note action
pub fn validate_submit_note(text : String) -> ActionResult {
  if text == "" {
    return ValidationError("Note text cannot be empty")
  }
  Success
}

///|
/// Validate submit draft action
pub fn validate_submit_draft(text : String) -> ActionResult {
  if text == "" {
    return ValidationError("Draft text cannot be empty")
  }
  if text.length() < 10 {
    return ValidationError("Draft text is too short (minimum 10 characters)")
  }
  Success
}

///|
/// Validate publish action
pub fn validate_publish(
  draft : @shared.Message,
  idempotency_key : String
) -> ActionResult {
  if not(draft.is_draft) {
    return StateError("Cannot publish a non-draft message")
  }
  if draft.draft_status != @shared.DraftStatus::Checked {
    return StateError(
      "Draft must be checked before publishing. Current status: \{draft.draft_status.to_string()}",
    )
  }
  if draft.published_at != "" {
    return StateError("Draft has already been published")
  }
  if idempotency_key == "" {
    return ValidationError("Idempotency key is required")
  }
  Success
}

/// =============================================================================
/// Action Handlers (Pure functions for state transitions)
/// =============================================================================

///|
/// Handle select ticket action - updates view state
pub fn handle_select_ticket(
  state : AppViewState,
  ticket_id : String
) -> AppViewState {
  // Update inbox selection
  let updated_tickets = state.inbox.tickets.map(
    fn(item) { { ..item, is_selected: item.ticket_id == ticket_id } },
  )
  let updated_inbox = { ..state.inbox, tickets: updated_tickets }

  // Clear workspace for new ticket
  let updated_workspace = WorkspacePaneState::initial()

  // Clear timeline for new ticket
  let updated_timeline = TimelinePaneState::initial()

  {
    ..state,
    inbox: updated_inbox,
    timeline: updated_timeline,
    workspace: updated_workspace,
    selected_ticket_id: ticket_id,
    error_message: "",
  }
}

///|
/// Handle filter tickets action
pub fn handle_filter_tickets(
  state : AppViewState,
  status : @shared.TicketStatus
) -> AppViewState {
  let updated_inbox = { ..state.inbox, filter_status: status, is_loading: true }
  { ..state, inbox: updated_inbox }
}

///|
/// Handle editor mode change
pub fn handle_set_editor_mode(
  state : AppViewState,
  mode : EditorMode
) -> AppViewState {
  let updated_workspace = { ..state.workspace, editor_mode: mode }
  { ..state, workspace: updated_workspace }
}

///|
/// Handle editor text update
pub fn handle_update_editor_text(
  state : AppViewState,
  text : String
) -> AppViewState {
  let updated_workspace = { ..state.workspace, editor_text: text }
  { ..state, workspace: updated_workspace }
}

///|
/// Handle show publish confirm
pub fn handle_show_publish_confirm(
  state : AppViewState,
  draft : @shared.Message,
  target_channel : String,
  idempotency_key : String
) -> AppViewState {
  let modal = PublishModalState::show(draft, target_channel, idempotency_key)
  { ..state, publish_modal: modal }
}

///|
/// Handle hide publish confirm
pub fn handle_hide_publish_confirm(state : AppViewState) -> AppViewState {
  { ..state, publish_modal: PublishModalState::hidden() }
}

///|
/// Handle dismiss error
pub fn handle_dismiss_error(state : AppViewState) -> AppViewState {
  { ..state, error_message: "" }
}

///|
/// Handle set connection status
pub fn handle_set_connection_status(
  state : AppViewState,
  connected : Bool
) -> AppViewState {
  { ..state, is_connected: connected }
}

///|
/// Set loading state for inbox
pub fn set_inbox_loading(state : AppViewState, loading : Bool) -> AppViewState {
  let updated_inbox = { ..state.inbox, is_loading: loading }
  { ..state, inbox: updated_inbox }
}

///|
/// Set loading state for timeline
pub fn set_timeline_loading(
  state : AppViewState,
  loading : Bool
) -> AppViewState {
  let updated_timeline = { ..state.timeline, is_loading: loading }
  { ..state, timeline: updated_timeline }
}

///|
/// Set submitting state for workspace
pub fn set_workspace_submitting(
  state : AppViewState,
  submitting : Bool
) -> AppViewState {
  let updated_workspace = { ..state.workspace, is_submitting: submitting }
  { ..state, workspace: updated_workspace }
}

///|
/// Set error message
pub fn set_error(state : AppViewState, message : String) -> AppViewState {
  { ..state, error_message: message }
}

///|
/// Update inbox with ticket list
pub fn update_inbox_tickets(
  state : AppViewState,
  tickets : Array[TicketListItem]
) -> AppViewState {
  let updated_inbox = { ..state.inbox, tickets, is_loading: false }
  { ..state, inbox: updated_inbox }
}

///|
/// Update timeline with messages
pub fn update_timeline_messages(
  state : AppViewState,
  messages : Array[TimelineMessage],
  subject : String
) -> AppViewState {
  let updated_timeline : TimelinePaneState = {
    messages,
    ticket_subject: subject,
    is_loading: false,
  }
  { ..state, timeline: updated_timeline }
}

///|
/// Update workspace with items
pub fn update_workspace_items(
  state : AppViewState,
  items : Array[WorkspaceItem]
) -> AppViewState {
  let updated_workspace = { ..state.workspace, items }
  { ..state, workspace: updated_workspace }
}

///|
/// Update review panel
pub fn update_review_panel(
  state : AppViewState,
  panel : ReviewPanelState
) -> AppViewState {
  let updated_workspace = { ..state.workspace, review_panel: panel }
  { ..state, workspace: updated_workspace }
}
