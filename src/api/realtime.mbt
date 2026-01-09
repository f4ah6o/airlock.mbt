///|
/// Real-time event handling and state synchronization
/// Connects WebSocket events to UI state updates

/// =============================================================================
/// Real-time State
/// =============================================================================

///|
/// Real-time synchronization state
pub(all) struct RealtimeState {
  ws_manager : WebSocketManager
  last_event_id : String           // For event ordering
  pending_syncs : Array[String]    // Ticket IDs needing sync
  typing_users : Map[String, Array[String]]  // ticket_id -> user_ids
} derive(Show, Eq)

///|
/// Create initial realtime state
pub fn RealtimeState::new(ws_url : String) -> RealtimeState {
  {
    ws_manager: WebSocketManager::new(WebSocketConfig::default(ws_url)),
    last_event_id: "",
    pending_syncs: [],
    typing_users: {},
  }
}

///|
/// Update WebSocket manager
pub fn RealtimeState::update_ws(
  self : RealtimeState,
  manager : WebSocketManager
) -> RealtimeState {
  { ..self, ws_manager: manager }
}

///|
/// Add ticket to pending syncs
pub fn RealtimeState::mark_needs_sync(
  self : RealtimeState,
  ticket_id : String
) -> RealtimeState {
  if self.pending_syncs.contains(ticket_id) {
    return self
  }
  let syncs = self.pending_syncs.copy()
  syncs.push(ticket_id)
  { ..self, pending_syncs: syncs }
}

///|
/// Remove ticket from pending syncs
pub fn RealtimeState::mark_synced(
  self : RealtimeState,
  ticket_id : String
) -> RealtimeState {
  let syncs = self.pending_syncs.filter(fn(id) { id != ticket_id })
  { ..self, pending_syncs: syncs }
}

///|
/// Set typing users for a ticket
pub fn RealtimeState::set_typing(
  self : RealtimeState,
  ticket_id : String,
  user_ids : Array[String]
) -> RealtimeState {
  let typing = self.typing_users
  typing.set(ticket_id, user_ids)
  { ..self, typing_users: typing }
}

///|
/// Add typing user
pub fn RealtimeState::add_typing_user(
  self : RealtimeState,
  ticket_id : String,
  user_id : String
) -> RealtimeState {
  let typing = self.typing_users
  let users = match typing.get(ticket_id) {
    Some(arr) =>
      if arr.contains(user_id) { arr } else {
        let new_arr = arr.copy()
        new_arr.push(user_id)
        new_arr
      }
    None => [user_id]
  }
  typing.set(ticket_id, users)
  { ..self, typing_users: typing }
}

///|
/// Remove typing user
pub fn RealtimeState::remove_typing_user(
  self : RealtimeState,
  ticket_id : String,
  user_id : String
) -> RealtimeState {
  let typing = self.typing_users
  match typing.get(ticket_id) {
    Some(arr) => {
      let filtered = arr.filter(fn(id) { id != user_id })
      if filtered.is_empty() {
        typing.remove(ticket_id)
      } else {
        typing.set(ticket_id, filtered)
      }
    }
    None => ()
  }
  { ..self, typing_users: typing }
}

///|
/// Get typing users for a ticket
pub fn RealtimeState::get_typing_users(
  self : RealtimeState,
  ticket_id : String
) -> Array[String] {
  match self.typing_users.get(ticket_id) {
    Some(users) => users
    None => []
  }
}

/// =============================================================================
/// Event Processing
/// =============================================================================

///|
/// Result of processing a server event
pub(all) enum EventProcessResult {
  NoAction
  UpdateInbox
  UpdateTimeline(String)          // ticket_id
  UpdateWorkspace(String)         // ticket_id
  UpdateAll(String)               // ticket_id
  ShowNotification(String)        // message
  Reconnect
} derive(Show, Eq)

///|
/// Process a server event and determine required actions
pub fn process_server_event(
  state : RealtimeState,
  event : ServerEvent
) -> (RealtimeState, EventProcessResult) {
  match event {
    // Ticket events
    TicketCreated(ticket_id) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateInbox)
    }

    TicketUpdated(ticket_id) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateAll(ticket_id))
    }

    TicketClosed(ticket_id) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateInbox)
    }

    // Message events
    NewMessage(ticket_id, _message_id) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateTimeline(ticket_id))
    }

    MessageUpdated(ticket_id, _message_id) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateTimeline(ticket_id))
    }

    // Draft events
    DraftStatusChanged(ticket_id, _message_id, _new_status) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateWorkspace(ticket_id))
    }

    DraftPublished(ticket_id, _message_id) => {
      let new_state = state.mark_needs_sync(ticket_id)
      (new_state, UpdateAll(ticket_id))
    }

    // User events
    UserJoined(_user_id) => (state, NoAction)
    UserLeft(_user_id) => (state, NoAction)

    Typing(ticket_id, user_id) => {
      let new_state = state.add_typing_user(ticket_id, user_id)
      (new_state, NoAction)
    }

    // Connection events
    Ping => {
      let ws = state.ws_manager.queue_event(ClientEvent::Pong)
      let new_state = state.update_ws(ws)
      (new_state, NoAction)
    }

    Pong => (state, NoAction)

    Error(msg) => (state, ShowNotification(msg))
  }
}

/// =============================================================================
/// Connection Lifecycle
/// =============================================================================

///|
/// Handle successful connection
pub fn on_connected(state : RealtimeState) -> RealtimeState {
  let ws = state.ws_manager.set_state(Connected)
  // Re-subscribe to all tracked tickets
  let ws_subscribed = state.subscribed_tickets().fold(
    init=ws,
    fn(manager, ticket_id) { manager.subscribe(ticket_id) },
  )
  state.update_ws(ws_subscribed)
}

///|
/// Handle connection closed
pub fn on_disconnected(state : RealtimeState) -> RealtimeState {
  let ws = state.ws_manager.set_state(Disconnected)
  state.update_ws(ws)
}

///|
/// Handle connection error
pub fn on_error(state : RealtimeState, error : String) -> RealtimeState {
  let ws = state.ws_manager.set_state(Error(error))
  state.update_ws(ws)
}

///|
/// Attempt reconnection
pub fn attempt_reconnect(state : RealtimeState) -> RealtimeState {
  if state.ws_manager.should_reconnect() {
    let ws = state.ws_manager.increment_reconnect()
    state.update_ws(ws)
  } else {
    state
  }
}

///|
/// Get subscribed tickets
fn RealtimeState::subscribed_tickets(self : RealtimeState) -> Array[String] {
  self.ws_manager.subscribed_tickets
}

/// =============================================================================
/// Subscription Management
/// =============================================================================

///|
/// Subscribe to ticket updates (when ticket is selected)
pub fn subscribe_to_ticket(
  state : RealtimeState,
  ticket_id : String
) -> RealtimeState {
  let ws = state.ws_manager.subscribe(ticket_id)
  state.update_ws(ws)
}

///|
/// Unsubscribe from ticket updates (when navigating away)
pub fn unsubscribe_from_ticket(
  state : RealtimeState,
  ticket_id : String
) -> RealtimeState {
  let ws = state.ws_manager.unsubscribe(ticket_id)
  state.update_ws(ws)
}

/// =============================================================================
/// Typing Indicators
/// =============================================================================

///|
/// Notify that current user started typing
pub fn start_typing(
  state : RealtimeState,
  ticket_id : String
) -> RealtimeState {
  let ws = state.ws_manager.queue_event(StartTyping(ticket_id))
  state.update_ws(ws)
}

///|
/// Notify that current user stopped typing
pub fn stop_typing(
  state : RealtimeState,
  ticket_id : String
) -> RealtimeState {
  let ws = state.ws_manager.queue_event(StopTyping(ticket_id))
  state.update_ws(ws)
}

/// =============================================================================
/// Integration with UI State
/// =============================================================================

///|
/// Full application state including realtime
pub(all) struct AppState {
  view : @ui.AppViewState
  realtime : RealtimeState
  current_user_id : String
} derive(Show, Eq)

///|
/// Create initial application state
pub fn AppState::initial(ws_url : String, user_id : String) -> AppState {
  {
    view: @ui.AppViewState::initial(),
    realtime: RealtimeState::new(ws_url),
    current_user_id: user_id,
  }
}

///|
/// Update view state
pub fn AppState::update_view(
  self : AppState,
  view : @ui.AppViewState
) -> AppState {
  { ..self, view }
}

///|
/// Update realtime state
pub fn AppState::update_realtime(
  self : AppState,
  realtime : RealtimeState
) -> AppState {
  { ..self, realtime }
}

///|
/// Handle WebSocket connection status change
pub fn AppState::on_connection_change(
  self : AppState,
  connected : Bool
) -> AppState {
  let view = @ui.handle_set_connection_status(self.view, connected)
  let realtime = if connected {
    on_connected(self.realtime)
  } else {
    on_disconnected(self.realtime)
  }
  { ..self, view, realtime }
}

///|
/// Select ticket and subscribe to updates
pub fn AppState::select_ticket(
  self : AppState,
  ticket_id : String
) -> AppState {
  // Unsubscribe from previous ticket if any
  let realtime1 = if self.view.selected_ticket_id != "" {
    unsubscribe_from_ticket(self.realtime, self.view.selected_ticket_id)
  } else {
    self.realtime
  }
  // Subscribe to new ticket
  let realtime2 = subscribe_to_ticket(realtime1, ticket_id)
  // Update view
  let view = @ui.handle_select_ticket(self.view, ticket_id)
  { ..self, view, realtime: realtime2 }
}
