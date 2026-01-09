///|
/// WebSocket abstraction layer for real-time updates
/// This provides a platform-independent interface for WebSocket communication
/// Actual implementation will be provided by Luna.mbt's JS FFI or native async

/// =============================================================================
/// Connection State
/// =============================================================================

///|
/// WebSocket connection states
pub(all) enum ConnectionState {
  Connecting
  Connected
  Disconnecting
  Disconnected
  Reconnecting(Int)  // Retry count
  Error(String)
} derive(Show, Eq)

///|
/// Check if connection is active
pub fn ConnectionState::is_active(self : ConnectionState) -> Bool {
  match self {
    Connected => true
    _ => false
  }
}

///|
/// Check if connection can send messages
pub fn ConnectionState::can_send(self : ConnectionState) -> Bool {
  self == Connected
}

/// =============================================================================
/// Real-time Event Types
/// =============================================================================

///|
/// Events received from server via WebSocket
pub(all) enum ServerEvent {
  // Ticket events
  TicketCreated(String)           // ticket_id
  TicketUpdated(String)           // ticket_id
  TicketClosed(String)            // ticket_id

  // Message events
  NewMessage(String, String)      // ticket_id, message_id
  MessageUpdated(String, String)  // ticket_id, message_id

  // Draft events
  DraftStatusChanged(String, String, String)  // ticket_id, message_id, new_status
  DraftPublished(String, String)              // ticket_id, message_id

  // System events
  UserJoined(String)              // user_id
  UserLeft(String)                // user_id
  Typing(String, String)          // ticket_id, user_id

  // Connection events
  Ping
  Pong
  Error(String)
} derive(Show, Eq)

///|
/// Events to send to server via WebSocket
pub(all) enum ClientEvent {
  // Subscription management
  Subscribe(String)               // ticket_id - subscribe to ticket updates
  Unsubscribe(String)             // ticket_id - unsubscribe from ticket

  // Presence
  StartTyping(String)             // ticket_id
  StopTyping(String)              // ticket_id

  // Connection
  Ping
  Pong
} derive(Show, Eq)

/// =============================================================================
/// WebSocket Configuration
/// =============================================================================

///|
/// WebSocket connection configuration
pub(all) struct WebSocketConfig {
  url : String                    // WebSocket server URL
  reconnect_delay_ms : Int        // Base delay for reconnection
  max_reconnect_attempts : Int    // Maximum reconnection attempts
  ping_interval_ms : Int          // Ping interval for keep-alive
  pong_timeout_ms : Int           // Timeout waiting for pong response
} derive(Show, Eq)

///|
/// Create default WebSocket configuration
pub fn WebSocketConfig::default(url : String) -> WebSocketConfig {
  {
    url,
    reconnect_delay_ms: 1000,
    max_reconnect_attempts: 10,
    ping_interval_ms: 30000,
    pong_timeout_ms: 5000,
  }
}

/// =============================================================================
/// WebSocket Manager State
/// =============================================================================

///|
/// WebSocket manager for handling real-time communication
pub(all) struct WebSocketManager {
  config : WebSocketConfig
  state : ConnectionState
  subscribed_tickets : Array[String]
  pending_events : Array[ClientEvent]
  reconnect_count : Int
} derive(Show, Eq)

///|
/// Create a new WebSocket manager
pub fn WebSocketManager::new(config : WebSocketConfig) -> WebSocketManager {
  {
    config,
    state: Disconnected,
    subscribed_tickets: [],
    pending_events: [],
    reconnect_count: 0,
  }
}

///|
/// Update connection state
pub fn WebSocketManager::set_state(
  self : WebSocketManager,
  state : ConnectionState
) -> WebSocketManager {
  let new_reconnect = match state {
    Connected => 0  // Reset on successful connection
    Reconnecting(n) => n
    _ => self.reconnect_count
  }
  { ..self, state, reconnect_count: new_reconnect }
}

///|
/// Subscribe to ticket updates
pub fn WebSocketManager::subscribe(
  self : WebSocketManager,
  ticket_id : String
) -> WebSocketManager {
  if self.subscribed_tickets.contains(ticket_id) {
    return self
  }
  let tickets = self.subscribed_tickets.copy()
  tickets.push(ticket_id)
  let events = self.pending_events.copy()
  events.push(Subscribe(ticket_id))
  { ..self, subscribed_tickets: tickets, pending_events: events }
}

///|
/// Unsubscribe from ticket updates
pub fn WebSocketManager::unsubscribe(
  self : WebSocketManager,
  ticket_id : String
) -> WebSocketManager {
  let tickets = self.subscribed_tickets.filter(fn(id) { id != ticket_id })
  let events = self.pending_events.copy()
  events.push(Unsubscribe(ticket_id))
  { ..self, subscribed_tickets: tickets, pending_events: events }
}

///|
/// Queue an event to send
pub fn WebSocketManager::queue_event(
  self : WebSocketManager,
  event : ClientEvent
) -> WebSocketManager {
  let events = self.pending_events.copy()
  events.push(event)
  { ..self, pending_events: events }
}

///|
/// Clear pending events (after successful send)
pub fn WebSocketManager::clear_pending(
  self : WebSocketManager
) -> WebSocketManager {
  { ..self, pending_events: [] }
}

///|
/// Get pending events
pub fn WebSocketManager::get_pending_events(
  self : WebSocketManager
) -> Array[ClientEvent] {
  self.pending_events
}

///|
/// Check if should attempt reconnection
pub fn WebSocketManager::should_reconnect(self : WebSocketManager) -> Bool {
  match self.state {
    Disconnected | Error(_) =>
      self.reconnect_count < self.config.max_reconnect_attempts
    _ => false
  }
}

///|
/// Calculate reconnection delay with exponential backoff
pub fn WebSocketManager::get_reconnect_delay(self : WebSocketManager) -> Int {
  // Exponential backoff: delay * 2^attempt (capped at 30 seconds)
  let base = self.config.reconnect_delay_ms
  let multiplier = 1 << self.reconnect_count  // 2^n
  let delay = base * multiplier
  if delay > 30000 { 30000 } else { delay }
}

///|
/// Increment reconnect counter
pub fn WebSocketManager::increment_reconnect(
  self : WebSocketManager
) -> WebSocketManager {
  {
    ..self,
    state: Reconnecting(self.reconnect_count + 1),
    reconnect_count: self.reconnect_count + 1,
  }
}

/// =============================================================================
/// Event Serialization (JSON format)
/// =============================================================================

///|
/// Serialize client event to JSON string
pub fn ClientEvent::to_json(self : ClientEvent) -> String {
  match self {
    Subscribe(ticket_id) =>
      "{\"type\":\"subscribe\",\"ticket_id\":\"\{ticket_id}\"}"
    Unsubscribe(ticket_id) =>
      "{\"type\":\"unsubscribe\",\"ticket_id\":\"\{ticket_id}\"}"
    StartTyping(ticket_id) =>
      "{\"type\":\"start_typing\",\"ticket_id\":\"\{ticket_id}\"}"
    StopTyping(ticket_id) =>
      "{\"type\":\"stop_typing\",\"ticket_id\":\"\{ticket_id}\"}"
    Ping => "{\"type\":\"ping\"}"
    Pong => "{\"type\":\"pong\"}"
  }
}

///|
/// Parse server event from JSON (simplified parser)
/// In real implementation, use proper JSON parsing library
pub fn parse_server_event(json : String) -> ServerEvent? {
  // Simple pattern matching for demo purposes
  // Real implementation would use JSON parser
  if json.contains("\"type\":\"ping\"") {
    return Some(Ping)
  }
  if json.contains("\"type\":\"pong\"") {
    return Some(Pong)
  }
  if json.contains("\"type\":\"error\"") {
    return Some(Error("Server error"))
  }
  if json.contains("\"type\":\"ticket_created\"") {
    // Extract ticket_id (simplified)
    return Some(TicketCreated("unknown"))
  }
  if json.contains("\"type\":\"new_message\"") {
    return Some(NewMessage("unknown", "unknown"))
  }
  if json.contains("\"type\":\"draft_published\"") {
    return Some(DraftPublished("unknown", "unknown"))
  }
  None
}
