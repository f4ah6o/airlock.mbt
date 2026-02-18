///|
/// Direct adapter backed by f4ah6o/direct_sdk
pub(all) struct DirectAdapter {
  config : AdapterConfig
  client : @rpc_client.Client
  mut state : AdapterState
  mut self_user_id : String
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
    self_user_id: "",
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
fn json_get_value(
  obj : Map[String, @direct_types.JsonValue],
  key : String,
) -> @direct_types.JsonValue? {
  obj.get(key)
}

///|
fn clip_text(text : String, limit? : Int = 180) -> String {
  let max_len = if limit <= 0 { 180 } else { limit }
  if text.length() <= max_len {
    return text
  }
  let sb = StringBuilder::new(size_hint=max_len + 3)
  for i in 0..<max_len {
    sb.write_char(text[i].unsafe_to_char())
  }
  sb.write_string("...")
  sb.to_string()
}

///|
fn parse_download_auth_value(
  value : @direct_types.JsonValue,
) -> Result[DownloadAuth, AdapterError] {
  let obj = match value {
    @direct_types.JsonObject(o) => o
    _ => return Err(UnknownError("create_download_auth response is not object"))
  }
  let url = {
    let get_url = json_get_string(obj, "get_url")
    if get_url != "" {
      get_url
    } else {
      json_get_string(obj, "url")
    }
  }
  let headers : Map[String, String] = {}
  match obj.get("get_headers") {
    Some(@direct_types.JsonObject(hs)) =>
      for kv in hs {
        let header_val = match json_string(kv.1) {
          Some(v) => v
          None => ""
        }
        if kv.0 != "" && header_val != "" {
          headers.set(kv.0, header_val)
        }
      }
    _ => ()
  }
  if url == "" {
    return Err(UnknownError("create_download_auth response missing url"))
  }
  Ok({ url, headers })
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
fn message_object_from_notify_payload(
  data : @direct_types.JsonValue,
) -> Map[String, @direct_types.JsonValue]? {
  match data {
    @direct_types.JsonObject(obj) =>
      match json_get_value(obj, "message") {
        Some(@direct_types.JsonObject(inner)) => Some(inner)
        _ => Some(obj)
      }
    @direct_types.JsonArray(arr) =>
      if !arr.is_empty() {
        message_object_from_notify_payload(arr[0])
      } else {
        None
      }
    _ => None
  }
}

///|
fn received_message_from_notify_payload(
  data : @direct_types.JsonValue,
) -> @direct_types.ReceivedMessage? {
  let obj = match message_object_from_notify_payload(data) {
    Some(v) => v
    None => return None
  }
  let id = {
    let message_id = json_get_string(obj, "message_id")
    if message_id != "" {
      message_id
    } else {
      json_get_string(obj, "id")
    }
  }
  if id == "" {
    return None
  }
  let talk_id = {
    let t = json_get_string(obj, "talk_id")
    if t != "" {
      t
    } else {
      json_get_string(obj, "room_id")
    }
  }
  let content = match json_get_value(obj, "content") {
    Some(v) => v
    None => @direct_types.JsonNull
  }
  let text = match content {
    @direct_types.JsonString(s) => s
    @direct_types.JsonObject(content_obj) => json_get_string(content_obj, "text")
    _ => ""
  }
  let msg_type = match json_get_int(obj, "type") {
    Some(v) =>
      match @direct_types.wire_to_msg_type(v) {
        Some(t) => t
        None => @direct_types.MsgTypeText
      }
    None => @direct_types.MsgTypeText
  }
  let created = match json_get_int(obj, "created") {
    Some(v) => v.to_int64()
    None => 0L
  }
  Some({
    id,
    talk_id,
    room_id: talk_id,
    user_id: json_get_string(obj, "user_id"),
    domain_id: json_get_string(obj, "domain_id"),
    text,
    msg_type,
    content,
    created,
    raw: Some(data),
  })
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
  let mut file_id = json_get_string(obj, "file_id")
  if file_id == "" {
    file_id = json_get_string(obj, "id")
  }
  let mut name = json_get_string(obj, "name")
  if name == "" {
    name = json_get_string(obj, "file_name")
  }
  if name == "" {
    name = json_get_string(obj, "filename")
  }
  if name == "" {
    name = json_get_string(obj, "attachment_name")
  }
  let mut mime = json_get_string(obj, "mime_type")
  if mime == "" {
    mime = json_get_string(obj, "content_type")
  }
  if mime == "" {
    mime = json_get_string(obj, "type")
  }
  if mime == "" {
    mime = json_get_string(obj, "attachment_content_type")
  }
  let mut url = json_get_string(obj, "url")
  if url == "" {
    url = json_get_string(obj, "get_url")
  }
  if url == "" {
    url = json_get_string(obj, "download_url")
  }
  if url == "" {
    url = json_get_string(obj, "attachment_url")
  }
  if url == "" {
    url = json_get_string(obj, "file_url")
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
  fn should_ignore_inbound(
    adapter : DirectAdapter,
    normalized : NormalizedMessage,
  ) -> Bool {
    if should_ignore_message(adapter.config, normalized) {
      return true
    }
    if adapter.self_user_id != "" && normalized.sender_id == adapter.self_user_id {
      return true
    }
    if adapter.config.bot_user_id != "" &&
      normalized.sender_name == adapter.config.bot_user_id {
      return true
    }
    false
  }
  @rpc_client.on(self.client, @direct_constants.EVENT_SESSION_CREATED, fn(_) {
    println("direct session created")
  })
  @rpc_client.on(self.client, @direct_constants.EVENT_SESSION_ERROR, fn(data) {
    println("direct session error: " + clip_text(data.to_string()))
  })
  @rpc_client.on(self.client, @direct_constants.EVENT_NOTIFICATION_ERROR, fn(data) {
    println("direct notification error: " + clip_text(data.to_string()))
  })
  @rpc_client.on(self.client, @direct_constants.EVENT_DECODE_ERROR, fn(data) {
    println("direct decode error: " + clip_text(data.to_string()))
  })
  @rpc_client.on_message(self.client, fn(message) {
    let normalized = direct_message_to_normalized(self.config, message)
    if should_ignore_inbound(self, normalized) {
      println(
        "direct inbound ignored(on_message): id=\{normalized.external_id} sender=\{normalized.sender_id}",
      )
      return
    }
    println(
      "direct inbound received(on_message): id=\{normalized.external_id} channel=\{normalized.channel_id} sender=\{normalized.sender_id}",
    )
    handler(normalized)
  })
  @rpc_client.on(self.client, "notify_create_message", fn(data) {
    println(
      "direct raw event: notify_create_message payload=\{clip_text(data.to_string())}",
    )
    match received_message_from_notify_payload(data) {
      Some(message) => {
        let normalized = direct_message_to_normalized(self.config, message)
        if should_ignore_inbound(self, normalized) {
          println(
            "direct inbound ignored(raw): id=\{normalized.external_id} sender=\{normalized.sender_id}",
          )
          return
        }
        println(
          "direct inbound received(raw): id=\{normalized.external_id} channel=\{normalized.channel_id} sender=\{normalized.sender_id}",
        )
        handler(normalized)
      }
      None =>
        println(
          "direct raw event parse skipped: payload=\{clip_text(data.to_string())}",
        )
    }
  })
  @rpc_client.on(self.client, "notify_create_attachment", fn(data) {
    println(
      "direct raw event: notify_create_attachment payload=\{clip_text(data.to_string())}",
    )
  })
}

///|
/// Connect to Direct and start background tasks
pub async fn DirectAdapter::connect(
  self : DirectAdapter,
  tasks : @async.TaskGroup[Unit],
) -> Result[Unit, AdapterError] {
  self.state = AdapterState::Connecting
  println("direct connect: open websocket")
  match @rpc_client.connect(self.client, tasks) {
    Ok(_) => {
      // direct_sdk connect returns before create_session completes.
      // Wait briefly for authenticated session to avoid false "connected" state.
      println("direct connect: websocket ok, waiting session auth")
      for _ in 0..<80 {
        if @rpc_client.is_authenticated(self.client) {
          match @direct_users.get_me(self.client) {
            Ok(me) => {
              self.self_user_id = @direct_types.id_to_string(me.id)
              if self.self_user_id != "" {
                println("direct connect: resolved self_user_id=" + self.self_user_id)
              }
            }
            Err(err) =>
              println(
                "direct connect: failed to resolve self user id: \{@direct_errors.direct_error_to_string(err)}",
              )
          }
          self.state = AdapterState::Connected
          println("direct connect: authenticated")
          return Ok(())
        }
        @async.sleep(100)
      }
      self.state = AdapterState::Error("session not authenticated")
      println(
        "direct connect: auth timeout connected=\{ @rpc_client.is_connected(self.client).to_string() } authenticated=\{ @rpc_client.is_authenticated(self.client).to_string() }",
      )
      Err(
        AuthenticationError(
          "session not authenticated (token invalid/expired or login failed)",
        ),
      )
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

pub async fn DirectAdapter::create_download_auth(
  self : DirectAdapter,
  file_id : String,
  talk_id? : String = "",
  message_id? : String = "",
) -> Result[DownloadAuth, AdapterError] {
  if file_id == "" || talk_id == "" || message_id == "" {
    return Err(
      UnknownError("talk_id, message_id, file_id are required"),
    )
  }
  let result = @direct_files.create_download_auth(
    self.client,
    @direct_types.string_to_id(talk_id),
    @direct_types.string_to_id(message_id),
    @direct_types.string_to_id(file_id),
  )
  match result {
    Ok(auth) => Ok({ url: auth.url, headers: auth.headers })
    Err(err) =>
      match err {
        @direct_errors.RPCError(400, _) => {
          let params : Array[Array[@direct_types.JsonValue]] = [
            [
              @direct_types.JsonString(talk_id),
              @direct_types.JsonString(message_id),
              @direct_types.JsonString(file_id),
            ],
            [
              @direct_types.JsonString(message_id),
              @direct_types.JsonString(talk_id),
              @direct_types.JsonString(file_id),
            ],
          ]
          for p in params {
            match @rpc_client.call(
              self.client,
              @direct_constants.METHOD_CREATE_DOWNLOAD_AUTH,
              p,
            ) {
              Ok(value) =>
                match parse_download_auth_value(value) {
                  Ok(auth) => return Ok(auth)
                  Err(_) => ()
                }
              Err(_) => ()
            }
          }
          Err(direct_error_to_adapter_error(err))
        }
        _ => Err(direct_error_to_adapter_error(err))
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
