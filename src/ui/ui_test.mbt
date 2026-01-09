///|
test "LayoutConfig default values" {
  let config = LayoutConfig::default()
  assert_eq(config.inbox_width_percent, 25)
  assert_eq(config.timeline_width_percent, 40)
  assert_eq(config.workspace_width_percent, 35)
  assert_eq(config.workspace_bg_color, "#fffbe6")
}

///|
test "AppUIState initial values" {
  let state = AppUIState::initial()
  assert_eq(state.selected_ticket_id, "")
  assert_eq(state.editor_mode, EditorMode::Note)
  assert_eq(state.draft_text, "")
  assert_eq(state.is_submitting, false)
  assert_eq(state.show_publish_modal, false)
  assert_eq(state.error_message, "")
}

///|
test "AppUIState select ticket" {
  let state = AppUIState::initial()
  let updated = state.select_ticket("tkt_001")
  assert_eq(updated.selected_ticket_id, "tkt_001")
}

///|
test "AppUIState set editor mode" {
  let state = AppUIState::initial()
  let updated = state.set_editor_mode(EditorMode::Draft)
  assert_eq(updated.editor_mode, EditorMode::Draft)
}

///|
test "AppUIState update draft" {
  let state = AppUIState::initial()
  let updated = state.update_draft("Hello world")
  assert_eq(updated.draft_text, "Hello world")
}

///|
test "AppUIState show/hide publish modal" {
  let state = AppUIState::initial()
  let shown = state.show_publish_confirm()
  assert_eq(shown.show_publish_modal, true)

  let hidden = shown.hide_publish_confirm()
  assert_eq(hidden.show_publish_modal, false)
}

///|
test "AppUIState error handling" {
  let state = AppUIState::initial()
  let with_error = state.set_error("Something went wrong")
  assert_eq(with_error.error_message, "Something went wrong")

  let cleared = with_error.clear_error()
  assert_eq(cleared.error_message, "")
}

///|
test "InboxPaneState initial" {
  let state = InboxPaneState::initial()
  assert_eq(state.tickets.length(), 0)
  assert_eq(state.filter_status, @shared.TicketStatus::Open)
  assert_eq(state.is_loading, false)
}

///|
test "TimelinePaneState initial" {
  let state = TimelinePaneState::initial()
  assert_eq(state.messages.length(), 0)
  assert_eq(state.ticket_subject, "")
  assert_eq(state.is_loading, false)
}

///|
test "WorkspacePaneState initial" {
  let state = WorkspacePaneState::initial()
  assert_eq(state.items.length(), 0)
  assert_true(state.current_draft is None)
  assert_eq(state.review_panel.is_visible, false)
  assert_eq(state.editor_mode, EditorMode::Note)
  assert_eq(state.editor_text, "")
  assert_eq(state.is_submitting, false)
}

///|
test "AppViewState initial" {
  let state = AppViewState::initial()
  assert_eq(state.selected_ticket_id, "")
  assert_eq(state.error_message, "")
  assert_eq(state.is_connected, false)
  assert_eq(state.publish_modal.is_visible, false)
}

///|
test "ReviewPanelState empty" {
  let panel = ReviewPanelState::empty()
  assert_eq(panel.is_visible, false)
  assert_eq(panel.draft_id, "")
  assert_eq(panel.warnings.length(), 0)
  assert_eq(panel.suggestions.length(), 0)
}

///|
test "PublishModalState hidden" {
  let modal = PublishModalState::hidden()
  assert_eq(modal.is_visible, false)
  assert_eq(modal.draft_id, "")
  assert_eq(modal.draft_preview, "")
}

///|
test "classes helper" {
  assert_eq(classes([]), "")
  assert_eq(classes(["a"]), "a")
  assert_eq(classes(["a", "b"]), "a b")
  assert_eq(classes(["a", "", "b"]), "a b")
}

///|
test "inline_style helper" {
  assert_eq(inline_style([]), "")
  assert_eq(inline_style([("color", "red")]), "color: red;")
  assert_eq(
    inline_style([("color", "red"), ("font-size", "12px")]),
    "color: red;font-size: 12px;",
  )
}

///|
test "get_draft_status_color" {
  assert_eq(get_draft_status_color("pending"), draft_pending_color)
  assert_eq(get_draft_status_color("checking"), draft_checking_color)
  assert_eq(get_draft_status_color("checked"), draft_checked_color)
  assert_eq(get_draft_status_color("rejected"), draft_rejected_color)
  assert_eq(get_draft_status_color("published"), draft_published_color)
  assert_eq(get_draft_status_color("unknown"), color_secondary)
}

///|
test "get_draft_status_label" {
  assert_eq(get_draft_status_label("pending"), "Pending")
  assert_eq(get_draft_status_label("checking"), "Checking...")
  assert_eq(get_draft_status_label("checked"), "Ready")
  assert_eq(get_draft_status_label("rejected"), "Needs Review")
  assert_eq(get_draft_status_label("published"), "Published")
  assert_eq(get_draft_status_label("unknown"), "unknown")
}

///|
test "validate_submit_note" {
  assert_true(validate_submit_note("").is_success() |> not)
  assert_true(validate_submit_note("Hello").is_success())
}

///|
test "validate_submit_draft" {
  assert_true(validate_submit_draft("").is_success() |> not)
  assert_true(validate_submit_draft("Short").is_success() |> not)
  assert_true(validate_submit_draft("This is a valid draft message").is_success())
}

///|
test "handle_select_ticket" {
  let state = AppViewState::initial()
  let updated = handle_select_ticket(state, "tkt_001")
  assert_eq(updated.selected_ticket_id, "tkt_001")
}

///|
test "handle_set_editor_mode" {
  let state = AppViewState::initial()
  let updated = handle_set_editor_mode(state, EditorMode::Draft)
  assert_eq(updated.workspace.editor_mode, EditorMode::Draft)
}

///|
test "handle_update_editor_text" {
  let state = AppViewState::initial()
  let updated = handle_update_editor_text(state, "Test message")
  assert_eq(updated.workspace.editor_text, "Test message")
}

///|
test "handle_dismiss_error" {
  let state = AppViewState::{ ..AppViewState::initial(), error_message: "Error!" }
  let updated = handle_dismiss_error(state)
  assert_eq(updated.error_message, "")
}

///|
test "handle_set_connection_status" {
  let state = AppViewState::initial()
  let connected = handle_set_connection_status(state, true)
  assert_eq(connected.is_connected, true)

  let disconnected = handle_set_connection_status(connected, false)
  assert_eq(disconnected.is_connected, false)
}
