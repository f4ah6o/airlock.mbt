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
fn user_info_display_name(user : @direct_types.UserInfo) -> String {
  if user.display_name != "" {
    user.display_name
  } else if user.name != "" {
    user.name
  } else {
    @direct_types.id_to_string(user.id)
  }
}

///|
fn upsert_user_map(
  users : Array[@direct_types.UserInfo],
  out : Map[String, String],
) -> Unit {
  for user in users {
    let user_id = @direct_types.id_to_string(user.id)
    let name = user_info_display_name(user)
    if user_id != "" && name != "" {
      out.set(user_id, name)
    }
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
/// Fetch known user display names from Direct API.
pub async fn DirectAdapter::fetch_known_user_names(
  self : DirectAdapter,
) -> Result[Array[(String, String)], AdapterError] {
  let result : Map[String, String] = {}
  let mut has_success = false
  let mut first_error : AdapterError? = None
  match @direct_users.get_friends(self.client) {
    Ok(users) => {
      has_success = true
      upsert_user_map(users, result)
    }
    Err(err) =>
      if first_error is None {
        first_error = Some(direct_error_to_adapter_error(err))
      }
  }
  match @direct_users.get_acquaintances(self.client) {
    Ok(users) => {
      has_success = true
      upsert_user_map(users, result)
    }
    Err(err) =>
      if first_error is None {
        first_error = Some(direct_error_to_adapter_error(err))
      }
  }
  match @direct_users.get_me(self.client) {
    Ok(me) =>
      match @direct_domains.get_domain_users(self.client, me.domain_id) {
        Ok(users) => {
          has_success = true
          upsert_user_map(users, result)
        }
        Err(err) =>
          if first_error is None {
            first_error = Some(direct_error_to_adapter_error(err))
          }
      }
    Err(err) =>
      if first_error is None {
        first_error = Some(direct_error_to_adapter_error(err))
      }
  }
  if has_success {
    let pairs : Array[(String, String)] = []
    for entry in result {
      pairs.push(entry)
    }
    Ok(pairs)
  } else {
    match first_error {
      Some(err) => Err(err)
      None => Err(UnknownError("failed to fetch direct user names"))
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
