///|
/// Direct adapter backed by f4ah6o/direct_sdk
pub(all) struct DirectAdapter {
  config : AdapterConfig
  client : @rpc_client.Client
  mut state : AdapterState
}

///|
/// Create a DirectAdapter with optional Direct SDK overrides
pub fn DirectAdapter::new(
  config : AdapterConfig,
  endpoint? : String = "",
  proxy_url? : String = "",
  bot_name? : String = "",
  debug? : Bool = false,
  timeout_ms? : Int = 0,
) -> DirectAdapter {
  let mut direct_cfg = @direct_config.new_config(config.api_token)
  if endpoint != "" {
    direct_cfg = @direct_config.with_endpoint(direct_cfg, endpoint)
  }
  if proxy_url != "" {
    direct_cfg = @direct_config.with_proxy(direct_cfg, proxy_url)
  }
  let name = if bot_name != "" { bot_name } else { config.platform_name }
  if name != "" {
    direct_cfg = @direct_config.with_name(direct_cfg, name)
  }
  if debug {
    direct_cfg = @direct_config.with_debug(direct_cfg, true)
  }
  if timeout_ms > 0 {
    direct_cfg = @direct_config.with_timeout(direct_cfg, timeout_ms)
  }
  {
    config,
    client: @rpc_client.new_client(direct_cfg),
    state: AdapterState::Disconnected,
  }
}

///|
pub fn DirectAdapter::platform_name(self : DirectAdapter) -> String {
  self.config.platform_name
}

///|
pub fn DirectAdapter::state(self : DirectAdapter) -> AdapterState {
  self.state
}

///|
/// Convert Direct received message into a normalized message
pub fn direct_message_to_normalized(
  config : AdapterConfig,
  message : @direct_types.ReceivedMessage,
) -> NormalizedMessage {
  let channel_id = if message.room_id != "" {
    message.room_id
  } else {
    message.talk_id
  }
  let sender_name = if message.user_id == "" {
    "unknown"
  } else {
    message.user_id
  }
  let raw_data = match message.raw {
    Some(raw) => raw.to_string()
    None => message.content.to_string()
  }
  {
    external_id: message.id,
    platform: config.platform_name,
    channel_id,
    sender_id: message.user_id,
    sender_name,
    text: message.text,
    attachments: [],
    timestamp: message.created.to_string(),
    is_bot: message.user_id == config.bot_user_id,
    reply_to_id: "",
    raw_data,
  }
}

///|
fn direct_error_to_adapter_error(
  err : @direct_errors.DirectError,
) -> AdapterError {
  match err {
    @direct_errors.ConnectionError(msg)
    | @direct_errors.NotConnected(msg)
    | @direct_errors.AlreadyConnected(msg) => ConnectionError(msg)
    @direct_errors.AuthError(msg) => AuthenticationError(msg)
    @direct_errors.RoomNotFound(msg) => InvalidChannel(msg)
    @direct_errors.Timeout(msg) => RateLimitError(msg)
    @direct_errors.DecodeError(msg)
    | @direct_errors.InvalidResponse(msg)
    | @direct_errors.UserNotFound(msg)
    | @direct_errors.InternalError(msg) => UnknownError(msg)
    @direct_errors.RPCError(code, msg) =>
      UnknownError("RPC error \{code.to_string()}: \{msg}")
  }
}

///|
/// Register a handler for incoming Direct messages
pub fn DirectAdapter::listen_incoming(
  self : DirectAdapter,
  handler : (NormalizedMessage) -> Unit,
) -> Unit {
  @rpc_client.on_message(self.client, fn(message) {
    let normalized = direct_message_to_normalized(self.config, message)
    if should_ignore_message(self.config, normalized) {
      return
    }
    handler(normalized)
  })
}

///|
/// Connect to Direct and start background tasks
pub async fn DirectAdapter::connect(
  self : DirectAdapter,
  tasks : @async.TaskGroup[Unit],
) -> Result[Unit, AdapterError] {
  self.state = AdapterState::Connecting
  match @rpc_client.connect(self.client, tasks) {
    Ok(_) => {
      self.state = AdapterState::Connected
      Ok(())
    }
    Err(e) => {
      self.state = AdapterState::Error(@direct_errors.direct_error_to_string(e))
      Err(direct_error_to_adapter_error(e))
    }
  }
}

///|
/// Disconnect from Direct
pub fn DirectAdapter::disconnect(
  self : DirectAdapter,
) -> Result[Unit, AdapterError] {
  match @rpc_client.close(self.client) {
    Ok(_) => {
      self.state = AdapterState::Disconnected
      Ok(())
    }
    Err(e) => {
      self.state = AdapterState::Error(@direct_errors.direct_error_to_string(e))
      Err(direct_error_to_adapter_error(e))
    }
  }
}

///|
/// Send an outbound message via Direct
pub async fn DirectAdapter::send_outbound(
  self : DirectAdapter,
  message : OutboundMessage,
) -> Result[SendResult, AdapterError] {
  if message.channel_id == "" {
    return Err(InvalidChannel("channel_id is required"))
  }
  if message.attachments.length() > 0 {
    return Err(MessageTooLong("Direct adapter does not support attachments"))
  }
  match @rpc_client.send_text(self.client, message.channel_id, message.text) {
    Ok(_) => Ok(SendResult::success("", ""))
    Err(e) => Err(direct_error_to_adapter_error(e))
  }
}
