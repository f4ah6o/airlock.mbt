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
fn is_blank_text(s : String) -> Bool {
  for c in s {
    if c != ' ' && c != '\n' && c != '\r' && c != '\t' {
      return false
    }
  }
  true
}

///|
fn starts_with(text : String, prefix : String) -> Bool {
  if text.length() < prefix.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if text[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn json_string(v : @direct_types.JsonValue) -> String? {
  match v {
    @direct_types.JsonString(s) => Some(s)
    @direct_types.JsonInt(i) => Some(i.to_string())
    @direct_types.JsonNumber(n) => Some(n.to_string())
    _ => None
  }
}

///|
fn json_int(v : @direct_types.JsonValue) -> Int? {
  match v {
    @direct_types.JsonInt(i) => Some(i.to_int())
    @direct_types.JsonNumber(n) => Some(n.to_int())
    _ => None
  }
}

///|
fn json_get_string(
  obj : Map[String, @direct_types.JsonValue],
  key : String,
) -> String {
  match obj.get(key) {
    Some(v) =>
      match json_string(v) {
        Some(s) => s
        None => ""
      }
    None => ""
  }
}

///|
fn json_get_int(
  obj : Map[String, @direct_types.JsonValue],
  key : String,
) -> Int? {
  match obj.get(key) {
    Some(v) => json_int(v)
    None => None
  }
}

///|
fn json_get_array(
  obj : Map[String, @direct_types.JsonValue],
  key : String,
) -> Array[@direct_types.JsonValue]? {
  match obj.get(key) {
    Some(@direct_types.JsonArray(arr)) => Some(arr)
    _ => None
  }
}

///|
fn json_array_to_strings(arr : Array[@direct_types.JsonValue]) -> Array[String] {
  let out : Array[String] = []
  for item in arr {
    match json_string(item) {
      Some(s) => if s != "" { out.push(s) }
      None => ()
    }
  }
  out
}

///|
fn message_type_name(msg_type : @direct_types.MessageType) -> String {
  match msg_type {
    @direct_types.MsgTypeText => "text"
    @direct_types.MsgTypeStamp => "stamp"
    @direct_types.MsgTypeOriginalStamp => "original-stamp"
    @direct_types.MsgTypeFile => "file"
    @direct_types.MsgTypeTextMultipleFile => "multi-file"
    @direct_types.MsgTypeSelect => "select"
    @direct_types.MsgTypeSelectReply => "select-reply"
    @direct_types.MsgTypeSelectClosed => "select-closed"
    @direct_types.MsgTypeYesNo => "yes-no"
    @direct_types.MsgTypeYesNoReply => "yes-no-reply"
    @direct_types.MsgTypeYesNoClosed => "yes-no-closed"
    @direct_types.MsgTypeTask => "task"
    @direct_types.MsgTypeTaskDone => "task-done"
    @direct_types.MsgTypeTaskClosed => "task-closed"
    @direct_types.MsgTypeLocation => "location"
    @direct_types.MsgTypeDeleted => "deleted"
    _ => "unknown"
  }
}

///|
fn merge_content_object(
  message : @direct_types.ReceivedMessage,
) -> Map[String, @direct_types.JsonValue]? {
  let merged : Map[String, @direct_types.JsonValue] = {}
  let mut has_any = false
  match message.raw {
    Some(@direct_types.JsonObject(raw_obj)) =>
      match raw_obj.get("content") {
        Some(@direct_types.JsonObject(raw_content)) => {
          for kv in raw_content {
            merged.set(kv.0, kv.1)
          }
          has_any = true
        }
        _ => ()
      }
    _ => ()
  }
  match message.content {
    @direct_types.JsonObject(content_obj) => {
      for kv in content_obj {
        merged.set(kv.0, kv.1)
      }
      has_any = true
    }
    _ => ()
  }
  if has_any {
    Some(merged)
  } else {
    None
  }
}

///|
fn attachment_type_from_mime(mime_or_type : String) -> @shared.AttachmentType {
  let lower = mime_or_type.to_lower()
  if starts_with(lower, "image/") {
    return @shared.Image
  }
  if starts_with(lower, "video/") {
    return @shared.Video
  }
  if starts_with(lower, "audio/") {
    return @shared.Audio
  }
  @shared.File
}

///|
fn parse_attachment_object(
  obj : Map[String, @direct_types.JsonValue],
) -> @shared.Attachment? {
  let file_id = {
    let v1 = json_get_string(obj, "file_id")
    if v1 != "" {
      v1
    } else {
      json_get_string(obj, "id")
    }
  }
  let mut name = json_get_string(obj, "name")
  if name == "" {
    name = json_get_string(obj, "file_name")
  }
  let mut mime = json_get_string(obj, "mime_type")
  if mime == "" {
    mime = json_get_string(obj, "content_type")
  }
  if mime == "" {
    mime = json_get_string(obj, "type")
  }
  let mut url = json_get_string(obj, "url")
  if url == "" {
    url = json_get_string(obj, "download_url")
  }
  if url == "" && file_id != "" {
    url = "direct://file/" + file_id
  }
  if name == "" {
    name = if file_id == "" { "attachment" } else { "file-" + file_id }
  }
  if url == "" {
    None
  } else {
    Some(@shared.Attachment::new(attachment_type_from_mime(mime), url, name))
  }
}

///|
fn collect_attachments(
  content_obj : Map[String, @direct_types.JsonValue],
) -> Array[@shared.Attachment] {
  let out : Array[@shared.Attachment] = []
  let seen : Map[String, Bool] = {}
  fn push_if_new(
    out : Array[@shared.Attachment],
    seen : Map[String, Bool],
    value : @shared.Attachment?,
  ) -> Unit {
    match value {
      Some(att) =>
        if seen.get(att.url) is None {
          seen.set(att.url, true)
          out.push(att)
        }
      None => ()
    }
  }
  push_if_new(out, seen, parse_attachment_object(content_obj))
  for key in ["files", "attachments"] {
    match json_get_array(content_obj, key) {
      Some(arr) =>
        for item in arr {
          match item {
            @direct_types.JsonObject(obj) =>
              push_if_new(out, seen, parse_attachment_object(obj))
            _ => ()
          }
        }
      None => ()
    }
  }
  out
}

///|
fn rendered_non_text(
  message : @direct_types.ReceivedMessage,
  content_obj : Map[String, @direct_types.JsonValue],
  attachments : Array[@shared.Attachment],
) -> String {
  match message.msg_type {
    @direct_types.MsgTypeStamp | @direct_types.MsgTypeOriginalStamp => {
      let stamp_set = json_get_string(content_obj, "stamp_set")
      let stamp_index = json_get_string(content_obj, "stamp_index")
      let stamp_text = json_get_string(content_obj, "text")
      let mut body = "[stamp]"
      if stamp_set != "" || stamp_index != "" {
        body = body + " " + stamp_set + ":" + stamp_index
      }
      if stamp_text != "" {
        body = body + " " + stamp_text
      }
      body
    }
    @direct_types.MsgTypeSelect | @direct_types.MsgTypeSelectClosed => {
      let question = json_get_string(content_obj, "question")
      let options = match json_get_array(content_obj, "options") {
        Some(arr) => json_array_to_strings(arr)
        None => []
      }
      let mut body = "[select]"
      if question != "" {
        body = body + " " + question
      }
      if !options.is_empty() {
        body = body + " / options: " + options.join(", ")
      }
      body
    }
    @direct_types.MsgTypeSelectReply => {
      let question = json_get_string(content_obj, "question")
      let options = match json_get_array(content_obj, "options") {
        Some(arr) => json_array_to_strings(arr)
        None => []
      }
      let response = json_get_int(content_obj, "response")
      let mut body = "[select-reply]"
      if question != "" {
        body = body + " " + question
      }
      match response {
        Some(idx) =>
          if idx >= 0 && idx < options.length() {
            body = body +
              " -> " +
              options[idx] +
              " (index=" +
              idx.to_string() +
              ")"
          } else {
            body = body + " -> index=" + idx.to_string()
          }
        None => ()
      }
      body
    }
    @direct_types.MsgTypeFile | @direct_types.MsgTypeTextMultipleFile =>
      if attachments.is_empty() {
        let name = json_get_string(content_obj, "name")
        if name != "" {
          "[file] " + name
        } else {
          "[file]"
        }
      } else {
        let names : Array[String] = []
        for att in attachments {
          names.push(att.name)
        }
        "[file] " + names.join(", ")
      }
    _ => "[" + message_type_name(message.msg_type) + "]"
  }
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
  let (rendered_text, attachments) = match merge_content_object(message) {
    Some(content_obj) => {
      let attachments = collect_attachments(content_obj)
      let rendered = rendered_non_text(message, content_obj, attachments)
      (rendered, attachments)
    }
    None => ("", [])
  }
  let mut text = message.text
  if is_blank_text(text) {
    text = rendered_text
  } else if (
      message.msg_type == @direct_types.MsgTypeFile ||
      message.msg_type == @direct_types.MsgTypeTextMultipleFile
    ) &&
    rendered_text != "" &&
    rendered_text != text {
    text = text + "\n" + rendered_text
  }
  if is_blank_text(text) {
    text = "[" + message_type_name(message.msg_type) + "]"
  }
  {
    external_id: message.id,
    platform: config.platform_name,
    channel_id,
    sender_id: message.user_id,
    sender_name,
    text,
    attachments,
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
