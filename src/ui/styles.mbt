///|
/// CSS Style Definitions for Airlock UI
/// These will be used for generating CSS classes and inline styles

/// =============================================================================
/// Color Palette
/// =============================================================================

///|
/// Primary colors
pub let color_primary : String = "#1a73e8"

///|
pub let color_primary_hover : String = "#1557b0"

///|
pub let color_secondary : String = "#5f6368"

///|
/// Background colors
pub let bg_workspace : String = "#fffbe6" // Warning/workspace zone

///|
pub let bg_inbox : String = "#f8f9fa"

///|
pub let bg_timeline : String = "#ffffff"

///|
pub let bg_selected : String = "#e8f0fe"

///|
pub let bg_hover : String = "#f1f3f4"

///|
/// Status colors
pub let color_success : String = "#34a853"

///|
pub let color_warning : String = "#fbbc04"

///|
pub let color_error : String = "#ea4335"

///|
pub let color_info : String = "#4285f4"

///|
/// Draft status colors
pub let draft_pending_color : String = "#9e9e9e"

///|
pub let draft_checking_color : String = "#ffc107"

///|
pub let draft_checked_color : String = "#4caf50"

///|
pub let draft_rejected_color : String = "#f44336"

///|
pub let draft_published_color : String = "#2196f3"

/// =============================================================================
/// Layout Dimensions
/// =============================================================================

///|
/// Pane widths (percentages)
pub let pane_inbox_width : Int = 25

///|
pub let pane_timeline_width : Int = 40

///|
pub let pane_workspace_width : Int = 35

///|
/// Common dimensions
pub let header_height : String = "56px"

///|
pub let message_padding : String = "12px"

///|
pub let border_radius : String = "8px"

///|
pub let shadow_light : String = "0 1px 2px rgba(0,0,0,0.1)"

///|
pub let shadow_medium : String = "0 2px 8px rgba(0,0,0,0.15)"

/// =============================================================================
/// CSS Class Names
/// =============================================================================

///|
/// Layout classes
pub let class_app_container : String = "airlock-app"

///|
pub let class_pane : String = "airlock-pane"

///|
pub let class_pane_inbox : String = "airlock-pane-inbox"

///|
pub let class_pane_timeline : String = "airlock-pane-timeline"

///|
pub let class_pane_workspace : String = "airlock-pane-workspace"

///|
/// Component classes
pub let class_ticket_item : String = "airlock-ticket-item"

///|
pub let class_ticket_selected : String = "airlock-ticket-selected"

///|
pub let class_message_bubble : String = "airlock-message"

///|
pub let class_message_user : String = "airlock-message-user"

///|
pub let class_message_support : String = "airlock-message-support"

///|
pub let class_draft_editor : String = "airlock-draft-editor"

///|
pub let class_review_panel : String = "airlock-review-panel"

///|
pub let class_publish_modal : String = "airlock-publish-modal"

///|
/// State classes
pub let class_loading : String = "airlock-loading"

///|
pub let class_error : String = "airlock-error"

///|
pub let class_success : String = "airlock-success"

///|
pub let class_disabled : String = "airlock-disabled"

/// =============================================================================
/// CSS Generation Helpers
/// =============================================================================

///|
/// Generate inline style string from key-value pairs
pub fn inline_style(styles : Array[(String, String)]) -> String {
  styles
  .map(fn(pair) {
    let (k, v) = pair
    "\{k}: \{v};"
  })
  .fold(init="", fn(acc, s) { acc + s })
}

///|
/// Generate class attribute string from class names
pub fn classes(class_names : Array[String]) -> String {
  class_names
  .filter(fn(c) { c != "" })
  .fold(init="", fn(acc, c) { if acc == "" { c } else { acc + " " + c } })
}

///|
/// Get draft status badge color
pub fn get_draft_status_color(status : String) -> String {
  match status {
    "pending" => draft_pending_color
    "checking" => draft_checking_color
    "checked" => draft_checked_color
    "rejected" => draft_rejected_color
    "published" => draft_published_color
    _ => color_secondary
  }
}

///|
/// Get draft status label
pub fn get_draft_status_label(status : String) -> String {
  match status {
    "pending" => "Pending"
    "checking" => "Checking..."
    "checked" => "Ready"
    "rejected" => "Needs Review"
    "published" => "Published"
    _ => status
  }
}

/// =============================================================================
/// Complete CSS Stylesheet
/// =============================================================================

///|
/// Generate complete CSS for the application
pub fn generate_stylesheet() -> String {
  let lines : Array[String] = [
    "/* Airlock UI Styles */",
    "@import url(\"https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap\");",
    "",
    ":root {",
    "  --mc-bg: #fff7e6;",
    "  --mc-surface: #ffffff;",
    "  --mc-border: #f1e1c7;",
    "  --mc-accent: #f97316;",
    "  --mc-accent-strong: #ea580c;",
    "  --mc-text: #1f2937;",
    "  --mc-muted: #6b7280;",
    "}",
    ".airlock-app {",
    "  display: flex;",
    "  height: 100vh;",
    "  font-family: \"Space Grotesk\", \"Noto Sans JP\", \"Segoe UI\", sans-serif;",
    "  background: linear-gradient(120deg, #f8f9fb 0%, #fdf4e7 50%, #f8f9fb 100%);",
    "}",
    "",
    ".airlock-pane {",
    "  display: flex;",
    "  flex-direction: column;",
    "  overflow: hidden;",
    "  border-right: 1px solid #e0e0e0;",
    "}",
    "",
    ".airlock-pane-inbox {",
    "  width: \{pane_inbox_width.to_string()}%;",
    "  background: \{bg_inbox};",
    "}",
    "",
    ".airlock-pane-timeline {",
    "  width: \{pane_timeline_width.to_string()}%;",
    "  background: \{bg_timeline};",
    "}",
    "",
    ".airlock-pane-workspace {",
    "  width: \{pane_workspace_width.to_string()}%;",
    "  background: \{bg_workspace};",
    "  border-right: none;",
    "}",
    "",
    "/* Ticket List */",
    ".airlock-ticket-item {",
    "  padding: 12px 16px;",
    "  border-bottom: 1px solid #e0e0e0;",
    "  cursor: pointer;",
    "  transition: background 0.15s;",
    "}",
    "",
    ".airlock-ticket-item:hover {",
    "  background: \{bg_hover};",
    "}",
    "",
    ".airlock-ticket-selected {",
    "  background: \{bg_selected};",
    "}",
    "",
    "/* Messages */",
    ".airlock-message {",
    "  max-width: 80%;",
    "  padding: \{message_padding};",
    "  margin: 8px;",
    "  border-radius: \{border_radius};",
    "  box-shadow: \{shadow_light};",
    "}",
    "",
    ".airlock-message-user {",
    "  background: #e3f2fd;",
    "  margin-left: auto;",
    "}",
    "",
    ".airlock-message-support {",
    "  background: #ffffff;",
    "  margin-right: auto;",
    "}",
    "",
    "/* Draft Editor */",
    ".airlock-draft-editor {",
    "  padding: 16px;",
    "  background: #ffffff;",
    "  border-radius: \{border_radius};",
    "  box-shadow: \{shadow_medium};",
    "  margin: 16px;",
    "}",
    "",
    "/* Review Panel */",
    ".airlock-review-panel {",
    "  background: #fff3e0;",
    "  border-left: 4px solid \{color_warning};",
    "  padding: 12px;",
    "  margin: 8px 16px;",
    "  border-radius: 4px;",
    "}",
    "",
    "/* Modal */",
    ".airlock-publish-modal {",
    "  position: fixed;",
    "  top: 0;",
    "  left: 0;",
    "  right: 0;",
    "  bottom: 0;",
    "  background: rgba(0,0,0,0.5);",
    "  display: flex;",
    "  align-items: center;",
    "  justify-content: center;",
    "}",
    "",
    "/* States */",
    ".airlock-loading {",
    "  opacity: 0.6;",
    "  pointer-events: none;",
    "}",
    "",
    ".airlock-disabled {",
    "  opacity: 0.5;",
    "  cursor: not-allowed;",
    "}",
    "",
    "/* Draft Status Badges */",
    ".draft-badge {",
    "  display: inline-block;",
    "  padding: 2px 8px;",
    "  border-radius: 12px;",
    "  font-size: 12px;",
    "  font-weight: 500;",
    "}",
    "",
    ".draft-badge-pending { background: #e0e0e0; color: #616161; }",
    ".draft-badge-checking { background: #fff3e0; color: #f57c00; }",
    ".draft-badge-checked { background: #e8f5e9; color: #388e3c; }",
    ".draft-badge-rejected { background: #ffebee; color: #d32f2f; }",
    ".draft-badge-published { background: #e3f2fd; color: #1976d2; }",
    "",
    "/* Buttons */",
    ".btn-primary {",
    "  background: \{color_primary};",
    "  color: white;",
    "  border: none;",
    "  padding: 8px 16px;",
    "  border-radius: 4px;",
    "  cursor: pointer;",
    "  font-weight: 500;",
    "}",
    "",
    ".btn-primary:hover {",
    "  background: \{color_primary_hover};",
    "}",
    "",
    ".btn-secondary {",
    "  background: transparent;",
    "  color: \{color_secondary};",
    "  border: 1px solid #dadce0;",
    "  padding: 8px 16px;",
    "  border-radius: 4px;",
    "  cursor: pointer;",
    "}",
    "",
    ".btn-danger {",
    "  background: \{color_error};",
    "  color: white;",
    "  border: none;",
    "  padding: 8px 16px;",
    "  border-radius: 4px;",
    "  cursor: pointer;",
    "}",
    "",
    "/* Moonchat */",
    ".airlock-moonchat {",
    "  display: flex;",
    "  flex-direction: column;",
    "  gap: 12px;",
    "  height: 100%;",
    "  padding: 12px;",
    "  background: var(--mc-bg);",
    "  border: 1px solid var(--mc-border);",
    "  border-radius: 12px;",
    "}",
    "",
    ".airlock-moonchat--timeline {",
    "  background: linear-gradient(160deg, #ffffff 0%, #f8f5ee 100%);",
    "}",
    "",
    ".airlock-moonchat--workspace {",
    "  background: linear-gradient(160deg, #fff7e6 0%, #fffdf5 100%);",
    "}",
    "",
    ".mc-message-list {",
    "  display: flex;",
    "  flex-direction: column;",
    "  gap: 12px;",
    "  flex: 1;",
    "  overflow: auto;",
    "  padding-right: 4px;",
    "}",
    "",
    ".mc-message-list__typing {",
    "  font-size: 12px;",
    "  color: var(--mc-muted);",
    "}",
    "",
    ".mc-message-bubble {",
    "  display: flex;",
    "  flex-direction: column;",
    "  gap: 8px;",
    "  padding: 12px 14px;",
    "  border-radius: 14px;",
    "  border: 1px solid var(--mc-border);",
    "  background: var(--mc-surface);",
    "  color: var(--mc-text);",
    "  max-width: 75%;",
    "  box-shadow: 0 10px 24px rgba(17, 24, 39, 0.08);",
    "}",
    "",
    ".mc-message-bubble--outbound {",
    "  align-self: flex-end;",
    "  border-color: rgba(249, 115, 22, 0.35);",
    "  background: rgba(249, 115, 22, 0.12);",
    "}",
    "",
    ".mc-message-bubble--inbound {",
    "  align-self: flex-start;",
    "}",
    "",
    ".mc-message-bubble--system {",
    "  align-self: center;",
    "  border: none;",
    "  background: transparent;",
    "  color: var(--mc-muted);",
    "  padding: 4px 0;",
    "  box-shadow: none;",
    "}",
    "",
    ".mc-message-bubble__meta {",
    "  display: flex;",
    "  gap: 12px;",
    "  font-size: 11px;",
    "  color: var(--mc-muted);",
    "  letter-spacing: 0.08em;",
    "  text-transform: uppercase;",
    "}",
    "",
    ".mc-message-bubble__author {",
    "  font-weight: 600;",
    "}",
    "",
    ".mc-message-bubble__body {",
    "  font-size: 14px;",
    "  line-height: 1.5;",
    "}",
    "",
    ".mc-message-bubble__markdown {",
    "  font-family: \"JetBrains Mono\", ui-monospace, monospace;",
    "  font-size: 13px;",
    "  color: #0f172a;",
    "}",
    "",
    ".mc-message-bubble__media {",
    "  display: grid;",
    "  gap: 8px;",
    "}",
    "",
    ".mc-message-bubble__image {",
    "  max-width: 100%;",
    "  border-radius: 12px;",
    "  border: 1px solid rgba(249, 115, 22, 0.2);",
    "}",
    "",
    ".mc-message-bubble__caption {",
    "  font-size: 11px;",
    "  color: var(--mc-muted);",
    "}",
    "",
    ".mc-message-bubble__status {",
    "  font-size: 11px;",
    "  color: var(--mc-muted);",
    "  align-self: flex-end;",
    "}",
    "",
    ".mc-input-area {",
    "  display: flex;",
    "  gap: 12px;",
    "  align-items: flex-end;",
    "}",
    "",
    ".mc-input-area__field {",
    "  flex: 1;",
    "  min-height: 72px;",
    "  padding: 12px 14px;",
    "  border-radius: 12px;",
    "  border: 1px solid var(--mc-border);",
    "  background: #fffdf7;",
    "  color: var(--mc-text);",
    "  font-family: \"Space Grotesk\", \"Noto Sans JP\", sans-serif;",
    "  font-size: 14px;",
    "  resize: vertical;",
    "}",
    "",
    ".mc-input-area__field:focus {",
    "  outline: none;",
    "  border-color: var(--mc-accent);",
    "  box-shadow: 0 0 0 3px rgba(249, 115, 22, 0.2);",
    "}",
    "",
    ".mc-input-area__send {",
    "  border: none;",
    "  border-radius: 12px;",
    "  padding: 12px 16px;",
    "  font-family: \"Space Grotesk\", \"Noto Sans JP\", sans-serif;",
    "  font-weight: 600;",
    "  color: #1f1300;",
    "  background: linear-gradient(135deg, var(--mc-accent), var(--mc-accent-strong));",
    "  cursor: pointer;",
    "  transition: transform 0.2s ease, box-shadow 0.2s ease;",
    "}",
    "",
    ".mc-input-area__send:hover {",
    "  transform: translateY(-1px);",
    "  box-shadow: 0 8px 20px rgba(249, 115, 22, 0.25);",
    "}",
    "",
    ".mc-input-area__send[disabled] {",
    "  opacity: 0.5;",
    "  cursor: not-allowed;",
    "  box-shadow: none;",
    "  transform: none;",
    "}",
    "",
    "@media (max-width: 720px) {",
    "  .airlock-pane {",
    "    flex: 1 0 100%;",
    "  }",
    "  .airlock-moonchat {",
    "    border-radius: 0;",
    "  }",
    "  .mc-input-area {",
    "    flex-direction: column;",
    "    align-items: stretch;",
    "  }",
    "}",
  ]
  lines.fold(init="", fn(acc, line) { acc + line + "\n" })
}
