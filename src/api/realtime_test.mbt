///|
test "RealtimeState new" {
  let state = RealtimeState::new("ws://localhost:8080")
  assert_eq(state.last_event_id, "")
  assert_eq(state.pending_syncs.length(), 0)
}

///|
test "RealtimeState mark_needs_sync" {
  let state = RealtimeState::new("ws://test")
  let synced = state.mark_needs_sync("tkt_001")
  assert_eq(synced.pending_syncs.length(), 1)

  // Duplicate should not add
  let dup = synced.mark_needs_sync("tkt_001")
  assert_eq(dup.pending_syncs.length(), 1)
}

///|
test "RealtimeState mark_synced" {
  let state = RealtimeState::new("ws://test").mark_needs_sync("tkt_001")
  let synced = state.mark_synced("tkt_001")
  assert_eq(synced.pending_syncs.length(), 0)
}

///|
test "RealtimeState typing users" {
  let state = RealtimeState::new("ws://test")

  // Add typing user
  let with_user = state.add_typing_user("tkt_001", "user_001")
  let users = with_user.get_typing_users("tkt_001")
  assert_eq(users.length(), 1)
  assert_eq(users[0], "user_001")

  // Add another user
  let with_two = with_user.add_typing_user("tkt_001", "user_002")
  let users2 = with_two.get_typing_users("tkt_001")
  assert_eq(users2.length(), 2)

  // Remove user
  let removed = with_two.remove_typing_user("tkt_001", "user_001")
  let users3 = removed.get_typing_users("tkt_001")
  assert_eq(users3.length(), 1)
  assert_eq(users3[0], "user_002")

  // Get typing for non-existent ticket
  let empty = state.get_typing_users("tkt_999")
  assert_eq(empty.length(), 0)
}

///|
test "process_server_event ticket events" {
  let state = RealtimeState::new("ws://test")
  let (new_state, result) = process_server_event(
    state,
    TicketCreated("tkt_001"),
  )
  assert_true(new_state.pending_syncs.contains("tkt_001"))
  assert_eq(result, UpdateInbox)
  let (_, result2) = process_server_event(state, TicketUpdated("tkt_001"))
  assert_eq(result2, UpdateAll("tkt_001"))
  let (_, result3) = process_server_event(state, TicketClosed("tkt_001"))
  assert_eq(result3, UpdateInbox)
}

///|
test "process_server_event message events" {
  let state = RealtimeState::new("ws://test")
  let (new_state, result) = process_server_event(
    state,
    NewMessage("tkt_001", "msg_001"),
  )
  assert_true(new_state.pending_syncs.contains("tkt_001"))
  assert_eq(result, UpdateTimeline("tkt_001"))
}

///|
test "process_server_event draft events" {
  let state = RealtimeState::new("ws://test")
  let (_, result) = process_server_event(
    state,
    DraftStatusChanged("tkt_001", "msg_001", "checked"),
  )
  assert_eq(result, UpdateWorkspace("tkt_001"))
  let (_, result2) = process_server_event(
    state,
    DraftPublished("tkt_001", "msg_001"),
  )
  assert_eq(result2, UpdateAll("tkt_001"))
}

///|
test "process_server_event ping" {
  let state = RealtimeState::new("ws://test")
  let (new_state, result) = process_server_event(state, ServerEvent::Ping)
  assert_eq(result, NoAction)
  // Should queue a pong
  assert_true(new_state.ws_manager.pending_events.length() > 0)
}

///|
test "process_server_event typing" {
  let state = RealtimeState::new("ws://test")
  let (new_state, result) = process_server_event(
    state,
    Typing("tkt_001", "user_001"),
  )
  assert_eq(result, NoAction)
  let users = new_state.get_typing_users("tkt_001")
  assert_eq(users.length(), 1)
}

///|
test "on_connected" {
  let state = RealtimeState::new("ws://test")
  let subscribed = state.update_ws(state.ws_manager.subscribe("tkt_001"))
  let connected = on_connected(subscribed)
  assert_eq(connected.ws_manager.state, ConnectionState::Connected)
}

///|
test "on_disconnected" {
  let state = RealtimeState::new("ws://test")
  let connected_state = state.update_ws(state.ws_manager.set_state(Connected))
  let disconnected = on_disconnected(connected_state)
  assert_eq(disconnected.ws_manager.state, ConnectionState::Disconnected)
}

///|
test "on_error" {
  let state = RealtimeState::new("ws://test")
  let error_state = on_error(state, "Connection failed")
  assert_eq(
    error_state.ws_manager.state,
    ConnectionState::Error("Connection failed"),
  )
}

///|
test "subscribe_to_ticket" {
  let state = RealtimeState::new("ws://test")
  let subscribed = subscribe_to_ticket(state, "tkt_001")
  assert_true(subscribed.ws_manager.subscribed_tickets.contains("tkt_001"))
}

///|
test "unsubscribe_from_ticket" {
  let state = RealtimeState::new("ws://test")
  let subscribed = subscribe_to_ticket(state, "tkt_001")
  let unsubscribed = unsubscribe_from_ticket(subscribed, "tkt_001")
  assert_false(unsubscribed.ws_manager.subscribed_tickets.contains("tkt_001"))
}

///|
test "start_typing and stop_typing" {
  let state = RealtimeState::new("ws://test")
  let typing = start_typing(state, "tkt_001")
  assert_true(typing.ws_manager.pending_events.length() > 0)
  let stopped = stop_typing(state, "tkt_001")
  assert_true(stopped.ws_manager.pending_events.length() > 0)
}

///|
test "AppState initial" {
  let state = AppState::initial("ws://localhost:8080", "user_001")
  assert_eq(state.current_user_id, "user_001")
  assert_eq(state.view.selected_ticket_id, "")
  assert_eq(state.realtime.ws_manager.state, ConnectionState::Disconnected)
}

///|
test "AppState on_connection_change" {
  let state = AppState::initial("ws://test", "user_001")
  let connected = state.on_connection_change(true)
  assert_true(connected.view.is_connected)
  assert_eq(connected.realtime.ws_manager.state, ConnectionState::Connected)
  let disconnected = connected.on_connection_change(false)
  assert_false(disconnected.view.is_connected)
  assert_eq(
    disconnected.realtime.ws_manager.state,
    ConnectionState::Disconnected,
  )
}

///|
test "AppState select_ticket" {
  let state = AppState::initial("ws://test", "user_001")
  let selected = state.select_ticket("tkt_001")
  assert_eq(selected.view.selected_ticket_id, "tkt_001")
  assert_true(
    selected.realtime.ws_manager.subscribed_tickets.contains("tkt_001"),
  )

  // Select another ticket
  let selected2 = selected.select_ticket("tkt_002")
  assert_eq(selected2.view.selected_ticket_id, "tkt_002")
  assert_true(
    selected2.realtime.ws_manager.subscribed_tickets.contains("tkt_002"),
  )
}
