///|
/// UI module placeholder for Luna.mbt integration
///
/// This module will contain:
/// - 3-pane layout components
/// - Ticket inbox (Pane 1)
/// - Public timeline (Pane 2)
/// - Workspace with draft editor (Pane 3)

/// Pane identifiers
pub(all) enum PaneId {
  Inbox      // Left pane - Ticket list
  Timeline   // Center pane - Public messages
  Workspace  // Right pane - Internal chat + draft editor
} derive(Show, Eq)

///|
/// Layout configuration
pub(all) struct LayoutConfig {
  inbox_width_percent : Int      // Default: 25%
  timeline_width_percent : Int   // Default: 40%
  workspace_width_percent : Int  // Default: 35%
  workspace_bg_color : String    // Default: #fffbe6 (warning color)
} derive(Show, Eq)

///|
/// Default layout configuration
pub fn LayoutConfig::default() -> LayoutConfig {
  {
    inbox_width_percent: 25,
    timeline_width_percent: 40,
    workspace_width_percent: 35,
    workspace_bg_color: "#fffbe6",
  }
}

///|
/// Draft editor mode
pub(all) enum EditorMode {
  Note   // Internal note only
  Draft  // Draft for publication
} derive(Show, Eq)

///|
/// UI state for the application
pub(all) struct AppUIState {
  selected_ticket_id : String   // Currently selected ticket
  editor_mode : EditorMode      // Current editor mode
  draft_text : String           // Current draft content
  is_submitting : Bool          // Whether submission is in progress
  show_publish_modal : Bool     // Whether publish confirmation is shown
  error_message : String        // Current error message (empty if none)
} derive(Show, Eq)

///|
/// Create initial UI state
pub fn AppUIState::initial() -> AppUIState {
  {
    selected_ticket_id: "",
    editor_mode: Note,
    draft_text: "",
    is_submitting: false,
    show_publish_modal: false,
    error_message: "",
  }
}

///|
/// Select a ticket
pub fn AppUIState::select_ticket(self : AppUIState, ticket_id : String) -> AppUIState {
  { ..self, selected_ticket_id: ticket_id, error_message: "" }
}

///|
/// Set editor mode
pub fn AppUIState::set_editor_mode(self : AppUIState, mode : EditorMode) -> AppUIState {
  { ..self, editor_mode: mode }
}

///|
/// Update draft text
pub fn AppUIState::update_draft(self : AppUIState, text : String) -> AppUIState {
  { ..self, draft_text: text }
}

///|
/// Show publish confirmation modal
pub fn AppUIState::show_publish_confirm(self : AppUIState) -> AppUIState {
  { ..self, show_publish_modal: true }
}

///|
/// Hide publish confirmation modal
pub fn AppUIState::hide_publish_confirm(self : AppUIState) -> AppUIState {
  { ..self, show_publish_modal: false }
}

///|
/// Set error message
pub fn AppUIState::set_error(self : AppUIState, message : String) -> AppUIState {
  { ..self, error_message: message }
}

///|
/// Clear error message
pub fn AppUIState::clear_error(self : AppUIState) -> AppUIState {
  { ..self, error_message: "" }
}

///|
/// Set submitting state
pub fn AppUIState::set_submitting(self : AppUIState, submitting : Bool) -> AppUIState {
  { ..self, is_submitting: submitting }
}
