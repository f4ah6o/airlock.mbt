///|
test "ConnectionState is_active" {
  assert_true(ConnectionState::Connected.is_active())
  assert_false(ConnectionState::Connecting.is_active())
  assert_false(ConnectionState::Disconnected.is_active())
  assert_false(ConnectionState::Reconnecting(1).is_active())
  assert_false(ConnectionState::Error("test").is_active())
}

///|
test "ConnectionState can_send" {
  assert_true(ConnectionState::Connected.can_send())
  assert_false(ConnectionState::Connecting.can_send())
  assert_false(ConnectionState::Disconnected.can_send())
}

///|
test "WebSocketConfig default" {
  let config = WebSocketConfig::default("ws://localhost:8080")
  assert_eq(config.url, "ws://localhost:8080")
  assert_eq(config.reconnect_delay_ms, 1000)
  assert_eq(config.max_reconnect_attempts, 10)
  assert_eq(config.ping_interval_ms, 30000)
  assert_eq(config.pong_timeout_ms, 5000)
}

///|
test "WebSocketManager new" {
  let config = WebSocketConfig::default("ws://test")
  let manager = WebSocketManager::new(config)
  assert_eq(manager.state, ConnectionState::Disconnected)
  assert_eq(manager.subscribed_tickets.length(), 0)
  assert_eq(manager.pending_events.length(), 0)
  assert_eq(manager.reconnect_count, 0)
}

///|
test "WebSocketManager set_state" {
  let config = WebSocketConfig::default("ws://test")
  let manager = WebSocketManager::new(config)

  let connected = manager.set_state(ConnectionState::Connected)
  assert_eq(connected.state, ConnectionState::Connected)
  assert_eq(connected.reconnect_count, 0)

  let reconnecting = manager.set_state(ConnectionState::Reconnecting(3))
  assert_eq(reconnecting.reconnect_count, 3)
}

///|
test "WebSocketManager subscribe" {
  let config = WebSocketConfig::default("ws://test")
  let manager = WebSocketManager::new(config)

  let subscribed = manager.subscribe("tkt_001")
  assert_eq(subscribed.subscribed_tickets.length(), 1)
  assert_eq(subscribed.pending_events.length(), 1)

  // Duplicate subscribe should not add
  let dup = subscribed.subscribe("tkt_001")
  assert_eq(dup.subscribed_tickets.length(), 1)
}

///|
test "WebSocketManager unsubscribe" {
  let config = WebSocketConfig::default("ws://test")
  let manager = WebSocketManager::new(config).subscribe("tkt_001")

  let unsubscribed = manager.unsubscribe("tkt_001")
  assert_eq(unsubscribed.subscribed_tickets.length(), 0)
}

///|
test "WebSocketManager should_reconnect" {
  let config = WebSocketConfig::default("ws://test")
  let manager = WebSocketManager::new(config)

  assert_true(manager.should_reconnect())

  let connected = manager.set_state(ConnectionState::Connected)
  assert_false(connected.should_reconnect())

  // After max attempts
  let max_attempts : WebSocketManager = {
    ..manager,
    reconnect_count: 10,
  }
  assert_false(max_attempts.should_reconnect())
}

///|
test "WebSocketManager get_reconnect_delay" {
  let config = WebSocketConfig::default("ws://test")
  let manager = WebSocketManager::new(config)

  // First attempt: 1000ms
  assert_eq(manager.get_reconnect_delay(), 1000)

  // Second attempt: 2000ms
  let attempt1 : WebSocketManager = { ..manager, reconnect_count: 1 }
  assert_eq(attempt1.get_reconnect_delay(), 2000)

  // Third attempt: 4000ms
  let attempt2 : WebSocketManager = { ..manager, reconnect_count: 2 }
  assert_eq(attempt2.get_reconnect_delay(), 4000)

  // Capped at 30000ms
  let attempt10 : WebSocketManager = { ..manager, reconnect_count: 10 }
  assert_eq(attempt10.get_reconnect_delay(), 30000)
}

///|
test "ClientEvent to_json" {
  assert_eq(
    ClientEvent::Subscribe("tkt_001").to_json(),
    "{\"type\":\"subscribe\",\"ticket_id\":\"tkt_001\"}",
  )
  assert_eq(ClientEvent::Ping.to_json(), "{\"type\":\"ping\"}")
  assert_eq(ClientEvent::Pong.to_json(), "{\"type\":\"pong\"}")
  assert_eq(
    ClientEvent::StartTyping("tkt_001").to_json(),
    "{\"type\":\"start_typing\",\"ticket_id\":\"tkt_001\"}",
  )
}

///|
test "parse_server_event" {
  let ping = parse_server_event("{\"type\":\"ping\"}")
  assert_true(ping is Some(ServerEvent::Ping))

  let pong = parse_server_event("{\"type\":\"pong\"}")
  assert_true(pong is Some(ServerEvent::Pong))

  let error = parse_server_event("{\"type\":\"error\",\"message\":\"test\"}")
  assert_true(error is Some(_))

  let unknown = parse_server_event("{\"type\":\"unknown\"}")
  assert_true(unknown is None)
}
