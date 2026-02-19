///|
fn bytes_to_array(b : Bytes) -> Array[Byte] {
  let arr : Array[Byte] = []
  for i in 0..<b.length() {
    arr.push(b[i])
  }
  arr
}

///|
fn array_to_bytes(arr : Array[Byte]) -> Bytes {
  Bytes::from_array(arr)
}

///|
fn string_to_bytes(s : String) -> Array[Byte] {
  let result : Array[Byte] = []
  for i in 0..<s.length() {
    result.push(s[i].to_int().to_byte())
  }
  result
}

///|
fn body_to_string(body : Array[Byte]) -> String {
  @utf8.decode_lossy(Bytes::from_array(body))
}

///|
fn split_form_pair(pair : String) -> (String, String) {
  let key = StringBuilder::new(size_hint=pair.length())
  let value = StringBuilder::new(size_hint=pair.length())
  let mut found_eq = false
  for c in pair {
    if !found_eq && c == '=' {
      found_eq = true
    } else if found_eq {
      value.write_char(c)
    } else {
      key.write_char(c)
    }
  }
  (key.to_string(), value.to_string())
}

///|
fn is_blank_text(s : String) -> Bool {
  let mut has_non_space = false
  for c in s {
    if c != ' ' && c != '\n' && c != '\r' && c != '\t' {
      has_non_space = true
      break
    }
  }
  !has_non_space
}

///|
fn hex_val_char(c : Char) -> Int? {
  let code = c.to_int()
  if code >= 48 && code <= 57 {
    return Some(code - 48)
  }
  if code >= 65 && code <= 70 {
    return Some(code - 55)
  }
  if code >= 97 && code <= 102 {
    return Some(code - 87)
  }
  None
}

///|
fn is_utf8_continuation_byte(b : Int) -> Bool {
  (b & 0xC0) == 0x80
}

///|
fn utf8_bytes_to_string(bytes : Array[Int]) -> String {
  let sb = StringBuilder::new(size_hint=bytes.length())
  let mut i = 0
  while i < bytes.length() {
    let b0 = bytes[i]
    if b0 < 0x80 {
      sb.write_char(Int::unsafe_to_char(b0))
      i = i + 1
    } else if b0 >= 0xC2 &&
      b0 <= 0xDF &&
      i + 1 < bytes.length() &&
      is_utf8_continuation_byte(bytes[i + 1]) {
      let b1 = bytes[i + 1]
      let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F)
      sb.write_char(Int::unsafe_to_char(cp))
      i = i + 2
    } else if b0 >= 0xE0 &&
      b0 <= 0xEF &&
      i + 2 < bytes.length() &&
      is_utf8_continuation_byte(bytes[i + 1]) &&
      is_utf8_continuation_byte(bytes[i + 2]) {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let valid = (b0 != 0xE0 || b1 >= 0xA0) && (b0 != 0xED || b1 <= 0x9F)
      if valid {
        let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F)
        sb.write_char(Int::unsafe_to_char(cp))
        i = i + 3
      } else {
        sb.write_char('\u{FFFD}')
        i = i + 1
      }
    } else if b0 >= 0xF0 &&
      b0 <= 0xF4 &&
      i + 3 < bytes.length() &&
      is_utf8_continuation_byte(bytes[i + 1]) &&
      is_utf8_continuation_byte(bytes[i + 2]) &&
      is_utf8_continuation_byte(bytes[i + 3]) {
      let b1 = bytes[i + 1]
      let b2 = bytes[i + 2]
      let b3 = bytes[i + 3]
      let valid = (b0 != 0xF0 || b1 >= 0x90) && (b0 != 0xF4 || b1 <= 0x8F)
      if valid {
        let cp = ((b0 & 0x07) << 18) |
          ((b1 & 0x3F) << 12) |
          ((b2 & 0x3F) << 6) |
          (b3 & 0x3F)
        sb.write_char(Int::unsafe_to_char(cp))
        i = i + 4
      } else {
        sb.write_char('\u{FFFD}')
        i = i + 1
      }
    } else {
      sb.write_char('\u{FFFD}')
      i = i + 1
    }
  }
  sb.to_string()
}

///|
fn url_decode(input : String) -> String {
  let sb = StringBuilder::new(size_hint=input.length())
  let pending_bytes : Array[Int] = []
  fn flush_pending(sb : StringBuilder, pending_bytes : Array[Int]) -> Unit {
    if !pending_bytes.is_empty() {
      sb.write_string(utf8_bytes_to_string(pending_bytes))
      pending_bytes.clear()
    }
  }
  let mut i = 0
  while i < input.length() {
    let c = input[i].unsafe_to_char()
    if c == '%' && i + 2 < input.length() {
      let c1 = input[i + 1].unsafe_to_char()
      let c2 = input[i + 2].unsafe_to_char()
      match (hex_val_char(c1), hex_val_char(c2)) {
        (Some(hi), Some(lo)) => {
          pending_bytes.push(hi * 16 + lo)
          i = i + 3
        }
        _ => {
          flush_pending(sb, pending_bytes)
          sb.write_char('%')
          i = i + 1
        }
      }
    } else if c == '+' {
      flush_pending(sb, pending_bytes)
      sb.write_char(' ')
      i = i + 1
    } else {
      flush_pending(sb, pending_bytes)
      sb.write_char(c)
      i = i + 1
    }
  }
  flush_pending(sb, pending_bytes)
  sb.to_string()
}

///|
fn parse_form(body : String) -> Map[String, String] {
  let result : Map[String, String] = {}
  if body == "" {
    return result
  }
  for pair_view in body.split("&") {
    let pair = pair_view.to_string()
    if pair == "" {
      continue
    }
    let (key, value) = split_form_pair(pair)
    result.set(url_decode(key), url_decode(value))
  }
  result
}

///|
fn url_encode_component(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length() + 16)
  for c in text {
    let code = c.to_int()
    let is_alpha_num = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122)
    let is_safe = is_alpha_num || c == '-' || c == '_' || c == '.' || c == '~'
    if is_safe {
      sb.write_char(c)
    } else {
      sb.write_char('%')
      let hi = (code / 16) & 0xF
      let lo = code & 0xF
      sb.write_char(if hi < 10 { Int::unsafe_to_char(48 + hi) } else { Int::unsafe_to_char(65 + hi - 10) })
      sb.write_char(if lo < 10 { Int::unsafe_to_char(48 + lo) } else { Int::unsafe_to_char(65 + lo - 10) })
    }
  }
  sb.to_string()
}

///|
fn query_string(uri : String) -> String {
  let mut q_idx : Int? = None
  for i in 0..<uri.length() {
    if uri[i] == '?' {
      q_idx = Some(i)
      break
    }
  }
  match q_idx {
    None => ""
    Some(idx) => {
      let sb = StringBuilder::new(size_hint=uri.length() - idx - 1)
      for i in (idx + 1)..<uri.length() {
        sb.write_char(uri[i].unsafe_to_char())
      }
      sb.to_string()
    }
  }
}

///|
fn parse_query(uri : String) -> Map[String, String] {
  parse_form(query_string(uri))
}

///|
fn split_path(path : String) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  for i in 0..<path.length() {
    let c = path[i]
    if c == '/' {
      if current != "" {
        result.push(current)
        current = ""
      }
    } else {
      current = current + c.unsafe_to_char().to_string()
    }
  }
  if current != "" {
    result.push(current)
  }
  result
}

///|
fn path_only(uri : String) -> String {
  let mut scheme_idx : Int? = None
  let mut i = 0
  while i + 2 < uri.length() {
    if uri[i] == ':' && uri[i + 1] == '/' && uri[i + 2] == '/' {
      scheme_idx = Some(i)
      break
    }
    i = i + 1
  }
  match scheme_idx {
    None => {
      let sb = StringBuilder::new(size_hint=uri.length())
      for c in uri {
        if c == '?' {
          break
        }
        sb.write_char(c)
      }
      let out = sb.to_string()
      if out == "" {
        "/"
      } else {
        out
      }
    }
    Some(idx) => {
      let mut j = idx + 3
      while j < uri.length() {
        if uri[j] == '/' {
          break
        }
        j = j + 1
      }
      if j >= uri.length() {
        return "/"
      }
      let sb = StringBuilder::new(size_hint=uri.length() - j)
      let mut k = j
      while k < uri.length() {
        if uri[k] == '?' {
          break
        }
        sb.write_char(uri[k].unsafe_to_char())
        k = k + 1
      }
      sb.to_string()
    }
  }
}

///|
struct AppState {
  ticket_repo : @core.TicketRepository
  message_repo : @core.MessageRepository
  id_counter : Ref[Int]
  dev_mode : Ref[Bool]
  realtime_version : Ref[Int]
  realtime_last_ticket_id : Ref[String]
  direct_adapter : Ref[@adapters.DirectAdapter?]
  direct_bridge_connecting : Ref[Bool]
  outbound_queue : Ref[Array[@adapters.OutboundMessage]]
  outbound_echo_counts : Ref[Map[String, Int]]
  direct_seen_external_ids : Ref[Map[String, Bool]]
  direct_seen_external_order : Ref[Array[String]]
  direct_user_name_cache : Ref[Map[String, String]]
  direct_user_names_loaded : Ref[Bool]
  direct_api_token : Ref[String]
  direct_attachment_host : Ref[String]
  s3_endpoint_url : Ref[String]
  awslim_s3_bin : Ref[String]
  s3_access_key_id : Ref[String]
  s3_secret_access_key : Ref[String]
  s3_region : Ref[String]
  attachment_proxy_map : Ref[Map[String, String]]
  attachment_upload_cmd : Ref[String]
}

///|
fn next_id(counter : Ref[Int], prefix : String) -> String {
  counter.val = counter.val + 1
  prefix + "-" + counter.val.to_string()
}

///|
fn seed_state() -> AppState {
  let ticket_repo = @core.TicketRepository::new()
  let message_repo = @core.MessageRepository::new()
  let id_counter : Ref[Int] = { val: 100 }
  let t1 = @shared.Ticket::new(
    "tkt-001",
    "VPN does not connect",
    @shared.ChatAMetadata::new("direct", "dm-001", ""),
  )
  let t2 = @shared.Ticket::new(
    "tkt-002",
    "Laptop is overheating",
    @shared.ChatAMetadata::new("direct", "dm-002", ""),
  )
  let _ = ticket_repo.create(t1)
  let _ = ticket_repo.create(t2)
  let m1 = @shared.Message::new(
    next_id(id_counter, "msg"),
    "tkt-001",
    "VPN fails with error 720.",
    @shared.Public,
    @shared.ChatA,
    "employee-a",
  )
  let m2 = @shared.Message::new(
    next_id(id_counter, "msg"),
    "tkt-001",
    "Acknowledged. Checking network policy.",
    @shared.Public,
    @shared.Console,
    "support",
  )
  let _ = message_repo.create(m1)
  let _ = message_repo.create(m2)
  {
    ticket_repo,
    message_repo,
    id_counter,
    dev_mode: { val: false },
    realtime_version: { val: 0 },
    realtime_last_ticket_id: { val: "" },
    direct_adapter: { val: None },
    direct_bridge_connecting: { val: false },
    outbound_queue: { val: [] },
    outbound_echo_counts: { val: {} },
    direct_seen_external_ids: { val: {} },
    direct_seen_external_order: { val: [] },
    direct_user_name_cache: { val: {} },
    direct_user_names_loaded: { val: false },
    direct_api_token: { val: "" },
    direct_attachment_host: { val: "api.direct4b.com" },
    s3_endpoint_url: { val: "http://127.0.0.1:9000" },
    awslim_s3_bin: { val: "../awslim/awslim-s3" },
    s3_access_key_id: { val: "rustfsadmin" },
    s3_secret_access_key: { val: "rustfsadmin" },
    s3_region: { val: "us-east-1" },
    attachment_proxy_map: { val: {} },
    attachment_upload_cmd: { val: "" },
  }
}

///|
fn should_send_to_direct(platform : String) -> Bool {
  platform == "direct4b" || platform == "direct"
}

///|
fn outbound_echo_key(channel_id : String, text : String) -> String {
  channel_id + "\n" + text
}

///|
fn register_outbound_echo(
  state : AppState,
  channel_id : String,
  text : String,
) -> Unit {
  let key = outbound_echo_key(channel_id, text)
  let next = match state.outbound_echo_counts.val.get(key) {
    Some(v) => v + 1
    None => 1
  }
  state.outbound_echo_counts.val.set(key, next)
}

///|
fn consume_outbound_echo(
  state : AppState,
  channel_id : String,
  text : String,
) -> Bool {
  let key = outbound_echo_key(channel_id, text)
  match state.outbound_echo_counts.val.get(key) {
    Some(v) => {
      if v <= 1 {
        state.outbound_echo_counts.val.remove(key)
      } else {
        state.outbound_echo_counts.val.set(key, v - 1)
      }
      true
    }
    None => false
  }
}

///|
fn mark_seen_direct_external_id(
  state : AppState,
  external_id : String,
) -> Bool {
  if external_id == "" {
    return false
  }
  match state.direct_seen_external_ids.val.get(external_id) {
    Some(_) => true
    None => {
      state.direct_seen_external_ids.val.set(external_id, true)
      state.direct_seen_external_order.val.push(external_id)
      let max_seen = 2048
      if state.direct_seen_external_order.val.length() > max_seen {
        let oldest = state.direct_seen_external_order.val[0]
        state.direct_seen_external_ids.val.remove(oldest)
        let next_order : Array[String] = []
        for i in 1..<state.direct_seen_external_order.val.length() {
          next_order.push(state.direct_seen_external_order.val[i])
        }
        state.direct_seen_external_order.val = next_order
      }
      false
    }
  }
}

///|
fn enqueue_direct_outbound(
  state : AppState,
  ticket : @shared.Ticket,
  text : String,
  idempotency_key : String,
) -> Unit {
  if !should_send_to_direct(ticket.chat_a.platform) {
    return
  }
  if ticket.chat_a.dm_id == "" {
    println("skip direct outbound: empty dm_id for ticket=\{ticket.ticket_id}")
    return
  }
  let outbound = @adapters.OutboundMessage::new(
    ticket.chat_a.dm_id,
    text,
    idempotency_key,
  )
  register_outbound_echo(state, ticket.chat_a.dm_id, text)
  state.outbound_queue.val.push(outbound)
}

///|
fn pop_outbound_queue(state : AppState) -> @adapters.OutboundMessage? {
  if state.outbound_queue.val.is_empty() {
    return None
  }
  let first = state.outbound_queue.val[0]
  let remaining : Array[@adapters.OutboundMessage] = []
  for i in 1..<state.outbound_queue.val.length() {
    remaining.push(state.outbound_queue.val[i])
  }
  state.outbound_queue.val = remaining
  Some(first)
}

///|
async fn process_outbound_queue_once(state : AppState) -> Unit {
  let adapter = match state.direct_adapter.val {
    Some(a) => a
    None => return
  }
  let outbound = match pop_outbound_queue(state) {
    Some(v) => v
    None => return
  }
  match adapter.send_outbound(outbound) {
    Ok(_) => ()
    Err(err) => {
      println("direct outbound failed: \{err.to_string()}")
      state.outbound_queue.val.push(outbound)
      match err {
        @adapters.ConnectionError(_) => {
          state.direct_adapter.val = None
          state.direct_user_names_loaded.val = false
          println("direct adapter reset: will retry connect")
        }
        _ => ()
      }
    }
  }
}

///|
async fn process_outbound_queue_loop(state : AppState) -> Unit {
  while true {
    process_outbound_queue_once(state)
    @async.sleep(200)
  }
}

///|
async fn maintain_direct_bridge_loop(
  state : AppState,
  ingest_ctx : @core.IngestContext,
  tasks : @async.TaskGroup[Unit],
) -> Unit {
  let mut retry_seq = 0
  while true {
    if state.direct_adapter.val is None && !state.direct_bridge_connecting.val {
      retry_seq = retry_seq + 1
      println("direct bridge retry: seq=\{retry_seq.to_string()}")
      state.direct_bridge_connecting.val = true
      try_start_direct_bridge(state, ingest_ctx, tasks)
      state.direct_bridge_connecting.val = false
    }
    @async.sleep(2000)
  }
}

///|
fn sse_event(event_name : String, data : String) -> String {
  "event: " + event_name + "\n" + "data: " + data + "\n\n"
}

///|
async fn send_sse_event(
  conn : @socket.Tcp,
  event_name : String,
  data : String,
) -> Unit {
  conn.write(array_to_bytes(string_to_bytes(sse_event(event_name, data))))
}

///|
fn notify_ticket_updated(state : AppState, ticket_id : String) -> Unit {
  state.realtime_version.val = state.realtime_version.val + 1
  state.realtime_last_ticket_id.val = ticket_id
}

///|
fn single_line_preview(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length())
  for c in text {
    if c == '\n' || c == '\r' || c == '\t' {
      sb.write_char(' ')
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string().trim().to_string()
}

///|
async fn handle_sse_subscribe(state : AppState, conn : @socket.Tcp) -> Unit {
  let header = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
  conn.write(array_to_bytes(string_to_bytes(header)))
  send_sse_event(conn, "connected", "{}")
  let mut seen_version = state.realtime_version.val
  while true {
    let current_version = state.realtime_version.val
    if current_version != seen_version {
      seen_version = current_version
      let ticket_id = state.realtime_last_ticket_id.val
      let ticket_subject = match state.ticket_repo.get(ticket_id) {
        Ok(t) => t.subject
        Err(_) => ""
      }
      let timeline = state.message_repo.list_public_by_ticket(ticket_id)
      let preview_message = if timeline.is_empty() {
        ""
      } else {
        single_line_preview(timeline[timeline.length() - 1].text)
      }
      let payload = "{\"ticket_id\":\"" +
        json_escape(ticket_id) +
        "\",\"version\":" +
        current_version.to_string() +
        ",\"subject\":\"" +
        json_escape(ticket_subject) +
        "\",\"preview\":\"" +
        json_escape(preview_message) +
        "\"}"
      send_sse_event(conn, "ticket-updated", payload)
    }
    @async.sleep(200)
  }
}

///|
fn build_response(
  status : Int,
  reason : String,
  body : String,
  content_type : String,
) -> @http.Response {
  let body_bytes = string_to_bytes(body)
  @http.Response::new(status, reason)
  .header("Content-Type", content_type)
  .header("Content-Length", body_bytes.length().to_string())
  .header("Connection", "close")
  .body(body_bytes)
}

///|
fn binary_response(
  status : Int,
  reason : String,
  body : Array[Byte],
  content_type : String,
  content_disposition? : String = "",
) -> @http.Response {
  let resp = @http.Response::new(status, reason)
  .header("Content-Type", content_type)
  .header("X-Content-Type-Options", "nosniff")
  .header("Content-Length", body.length().to_string())
  .header("Connection", "close")
  if content_disposition != "" {
    resp.header("Content-Disposition", content_disposition).body(body)
  } else {
    resp.body(body)
  }
}

///|
fn html_response(body : String) -> @http.Response {
  build_response(200, "OK", body, "text/html; charset=utf-8")
}

///|
fn html_error_response(
  status : Int,
  reason : String,
  body : String,
) -> @http.Response {
  build_response(status, reason, body, "text/html; charset=utf-8")
}

///|
fn not_found_response() -> @http.Response {
  build_response(404, "Not Found", "404 Not Found", "text/plain; charset=utf-8")
}

///|
fn forbidden_response(msg : String) -> @http.Response {
  build_response(403, "Forbidden", msg, "text/plain; charset=utf-8")
}

///|
fn bad_gateway_response(msg : String) -> @http.Response {
  build_response(502, "Bad Gateway", msg, "text/plain; charset=utf-8")
}

///|
fn js_response(body : String) -> @http.Response {
  build_response(200, "OK", body, "application/javascript; charset=utf-8")
}

///|
fn redirect_to_ticket(ticket_id : String) -> @http.Response {
  @http.Response::new(303, "See Other")
  .header("Location", "/tickets/" + ticket_id)
  .header("Content-Length", "0")
  .header("Connection", "close")
}

///|
fn closed_ticket_response(
  mhx_request : Bool,
  pane : String,
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
  notes : Array[@shared.Message],
) -> @http.Response {
  let msg = "Ticket is closed. New replies/notes are not allowed."
  if mhx_request {
    if pane == "center" {
      return html_error_response(
        409,
        "Conflict",
        @web.render_center_partial(ticket, timeline, Some(msg)),
      )
    }
    return html_error_response(
      409,
      "Conflict",
      @web.render_right_partial(ticket, notes, Some(msg)),
    )
  }
  build_response(409, "Conflict", msg, "text/plain; charset=utf-8")
}

///|
fn read_asset(path : String) -> String? {
  if !@fs.path_exists(path) {
    return None
  }
  let result : Result[String, Error] = try? @fs.read_file_to_string(path)
  match result {
    Ok(content) => Some(content)
    Err(_) => None
  }
}

///|
fn ascii_lower_u16(c : UInt16) -> Int {
  let code = c.to_int()
  if code >= 65 && code <= 90 {
    return code + 32
  }
  code
}

///|
fn ascii_eq_ignore_case(a : String, b : String) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if ascii_lower_u16(a[i]) != ascii_lower_u16(b[i]) {
      return false
    }
  }
  true
}

///|
fn ticket_bucket(status : @shared.TicketStatus) -> Int {
  match status {
    @shared.Open => 0
    @shared.Pending => 1
    @shared.Closed => 2
  }
}

///|
fn subject_from_text(text : String) -> String {
  if is_blank_text(text) {
    return "Inbound message"
  }
  let sb = StringBuilder::new(size_hint=text.length())
  for c in text {
    if c == '\n' || c == '\r' {
      break
    }
    sb.write_char(c)
  }
  let out = sb.to_string().trim().to_string()
  if out == "" {
    "Inbound message"
  } else {
    out
  }
}

///|
fn ticket_subject_for_view(state : AppState, ticket : @shared.Ticket) -> String {
  let mut latest : String? = None
  for message in state.message_repo.list_public_by_ticket(ticket.ticket_id) {
    if message.origin == @shared.ChatA && !is_blank_text(message.text) {
      latest = Some(message.text)
    }
  }
  match latest {
    Some(text) => subject_from_text(text)
    None => ticket.subject
  }
}

///|
fn ticket_for_view(state : AppState, ticket : @shared.Ticket) -> @shared.Ticket {
  @shared.Ticket::{ ..ticket, subject: ticket_subject_for_view(state, ticket) }
}

///|
fn ticket_view_list(state : AppState) -> Array[@shared.Ticket] {
  let buckets : Array[Array[@shared.Ticket]] = [[], [], []]
  for raw_ticket in state.ticket_repo.list() {
    let ticket = ticket_for_view(state, raw_ticket)
    buckets[ticket_bucket(ticket.status)].push(ticket)
  }
  let merged : Array[@shared.Ticket] = []
  for bucket in buckets {
    for ticket in bucket {
      merged.push(ticket)
    }
  }
  merged
}

///|
fn full_page_response(
  state : AppState,
  preferred_ticket_id : String?,
) -> @http.Response {
  let tickets = ticket_view_list(state)
  let selected = match preferred_ticket_id {
    Some(ticket_id) =>
      match state.ticket_repo.get(ticket_id) {
        Ok(t) => Some(ticket_for_view(state, t))
        Err(_) => if tickets.is_empty() { None } else { Some(tickets[0]) }
      }
    None => if tickets.is_empty() { None } else { Some(tickets[0]) }
  }
  let timeline = match selected {
    None => []
    Some(t) => state.message_repo.list_public_by_ticket(t.ticket_id)
  }
  let notes = match selected {
    None => []
    Some(t) =>
      state.message_repo
      .list_workspace_by_ticket(t.ticket_id)
      .filter(fn(m) { m.visibility == @shared.Internal })
  }
  html_response(@web.render_index(tickets, selected, timeline, notes))
}

///|
async fn try_load_direct_user_names_once(state : AppState) -> Unit {
  if state.direct_user_names_loaded.val {
    return
  }
  let mut added = 0
  fn upsert_name(
    state : AppState,
    user_id : String,
    name : String,
    added_counter : Ref[Int],
  ) -> Unit {
    if user_id == "" || name == "" {
      return
    }
    if state.direct_user_name_cache.val.get(user_id) is None {
      added_counter.val = added_counter.val + 1
    }
    state.direct_user_name_cache.val.set(user_id, name)
  }
  let added_counter : Ref[Int] = { val: 0 }
  let adapter = match state.direct_adapter.val {
    Some(v) => v
    None => {
      println("direct user-name lookup skipped: adapter is not connected")
      return
    }
  }
  match adapter.fetch_known_user_names() {
    Ok(entries) =>
      for pair in entries {
        let (user_id, name) = pair
        upsert_name(state, user_id, name, added_counter)
      }
    Err(err) =>
      println("failed to load direct user names: \{clip_for_error(err.to_string())}")
  }
  added = added_counter.val
  if added == 0 {
    let token = state.direct_api_token.val
    if token != "" {
      let talks_result = try? @direct_api_talks.get_talks(token)
      match talks_result {
        Ok(talks) => {
          for talk in talks {
            for user in talk.users {
              upsert_name(state, user.user_id_str, user.name, added_counter)
            }
          }
          added = added_counter.val
        }
        Err(err) =>
          println(
            "failed to load direct user names via direct-api: \{clip_for_error(err.to_string())}",
          )
      }
    }
  }
  println(
    "loaded direct user names: added=\{added.to_string()} cache_size=\{state.direct_user_name_cache.val.length().to_string()}",
  )
  state.direct_user_names_loaded.val = true
}

///|
fn fill_sender_names_from_cache(state : AppState, ticket_id : String) -> Unit {
  if state.direct_user_name_cache.val.is_empty() {
    return
  }
  let messages = state.message_repo.list_by_ticket(ticket_id)
  for message in messages {
    match state.direct_user_name_cache.val.get(message.sender_id) {
      Some(name) =>
        if name != "" && message.sender_name != name {
          let updated = @shared.Message::{ ..message, sender_name: name }
          let _ = state.message_repo.update(updated)
        }
      None => ()
    }
  }
}

///|
async fn ensure_ticket_open_context(
  state : AppState,
  ticket_id : String,
) -> Unit {
  try_load_direct_user_names_once(state)
  fill_sender_names_from_cache(state, ticket_id)
}

///|
fn is_mhx_request(request : @http.Request) -> Bool {
  for header in request.headers {
    let (name, value) = header
    if ascii_eq_ignore_case(name, "HX-Request") &&
      ascii_eq_ignore_case(value, "true") {
      return true
    }
  }
  false
}

///|
fn trim_trailing_slash(url : String) -> String {
  if url.length() > 0 && url[url.length() - 1] == '/' {
    let sb = StringBuilder::new(size_hint=url.length() - 1)
    for i in 0..<(url.length() - 1) {
      sb.write_char(url[i].unsafe_to_char())
    }
    sb.to_string()
  } else {
    url
  }
}

///|
fn url_host(url : String) -> String {
  let mut scheme_end = -1
  let mut i = 0
  while i + 2 < url.length() {
    if url[i] == ':' && url[i + 1] == '/' && url[i + 2] == '/' {
      scheme_end = i + 3
      break
    }
    i = i + 1
  }
  if scheme_end < 0 || scheme_end >= url.length() {
    return ""
  }
  let mut end = url.length()
  for j in scheme_end..<url.length() {
    if url[j] == '/' || url[j] == '?' || url[j] == '#' {
      end = j
      break
    }
  }
  if end <= scheme_end {
    return ""
  }
  let authority = substring(url, scheme_end, end)
  for k in 0..<authority.length() {
    if authority[k] == ':' {
      if k == 0 {
        return ""
      }
      return substring(authority, 0, k)
    }
  }
  authority
}

///|
fn json_escape(s : String) -> String {
  let sb = StringBuilder::new(size_hint=s.length() + 8)
  for c in s {
    if c == '\\' {
      sb.write_string("\\\\")
    } else if c == '"' {
      sb.write_string("\\\"")
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn is_allowed_proxy_url(state : AppState, url : String) -> Bool {
  let host = url_host(url)
  if host != "" &&
    (host == "api.direct4b.com" || host == state.direct_attachment_host.val) {
    return true
  }
  let endpoint = trim_trailing_slash(state.s3_endpoint_url.val)
  if endpoint != "" && has_prefix(url, endpoint + "/") {
    return true
  }
  false
}

fn substring(text : String, start : Int, end_ : Int) -> String {
  let sb = StringBuilder::new(size_hint=end_ - start)
  for i in start..<end_ {
    sb.write_char(text[i].unsafe_to_char())
  }
  sb.to_string()
}

///|
fn clip_for_error(text : String, limit? : Int = 220) -> String {
  let max_len = if limit <= 0 { 220 } else { limit }
  if text.length() <= max_len {
    return text
  }
  substring(text, 0, max_len) + "..."
}

///|
fn sanitize_filename(name : String) -> String {
  let trimmed = name.trim().to_string()
  if trimmed == "" {
    return ""
  }
  let sb = StringBuilder::new(size_hint=trimmed.length())
  for c in trimmed {
    if c == '/' || c == '\\' || c == '"' || c == '\n' || c == '\r' || c == '\t' {
      sb.write_char('_')
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn content_disposition_for_download(name : String) -> String {
  let safe = sanitize_filename(name)
  if safe == "" {
    ""
  } else {
    "attachment; filename=\"" + safe + "\""
  }
}

///|
fn content_disposition_for_inline(name : String) -> String {
  let safe = sanitize_filename(name)
  if safe == "" {
    ""
  } else {
    "inline; filename=\"" + safe + "\""
  }
}

///|
fn ascii_lower(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length())
  for i in 0..<text.length() {
    let code = ascii_lower_u16(text[i])
    sb.write_char(Int::unsafe_to_char(code))
  }
  sb.to_string()
}

///|
fn has_suffix(text : String, suffix : String) -> Bool {
  if suffix.length() > text.length() {
    return false
  }
  let start = text.length() - suffix.length()
  for i in 0..<suffix.length() {
    if text[start + i] != suffix[i] {
      return false
    }
  }
  true
}

///|
fn infer_image_mime_from_name(name : String) -> String? {
  let safe = sanitize_filename(name)
  let lower = ascii_lower(safe)
  if has_suffix(lower, ".png") {
    return Some("image/png")
  }
  if has_suffix(lower, ".jpg") || has_suffix(lower, ".jpeg") {
    return Some("image/jpeg")
  }
  if has_suffix(lower, ".gif") {
    return Some("image/gif")
  }
  if has_suffix(lower, ".webp") {
    return Some("image/webp")
  }
  None
}

///|
fn is_truthy_query(v : String) -> Bool {
  let lower = ascii_lower(v.trim().to_string())
  lower == "1" || lower == "true" || lower == "yes"
}

///|
async fn fetch_direct_attachment_bytes(
  state : AppState,
  url : String,
) -> Result[Array[Byte], String] {
  let token = state.direct_api_token.val
  if token != "" {
    let url_with_auth = if (
        (has_prefix(url, "https://api.direct4b.com/") ||
          has_prefix(url, "http://api.direct4b.com/")) &&
        !contains_text(url, "Authorization=")
      ) {
      let separator = if contains_text(url, "?") { "&" } else { "?" }
      url + separator + "Authorization=ALB%20" + token
    } else {
      url
    }
    let (exit_code, out, err) = @process.collect_output(
      "curl",
      ["-fsSL", url_with_auth],
    )
    if exit_code == 0 {
      return Ok(out.binary().to_array())
    }
    let err_text_result = try? err.text()
    let err_text = match err_text_result {
      Ok(v) => clip_for_error(v.trim().to_string())
      Err(_) => "stderr unreadable"
    }
    println(
      "direct attachment fetch failed with ALB query auth: exit=\{exit_code.to_string()} err=\{err_text}",
    )
    for header in [
      "Authorization: Bearer " + token,
      "X-Auth-Token: " + token,
      "X-API-Token: " + token,
    ] {
      let (exit_code, out, err) = @process.collect_output(
        "curl",
        ["-fsSL", "-H", header, url],
      )
      if exit_code == 0 {
        return Ok(out.binary().to_array())
      }
      let err_text_result = try? err.text()
      let err_text = match err_text_result {
        Ok(v) => clip_for_error(v.trim().to_string())
        Err(_) => "stderr unreadable"
      }
      println(
        "direct attachment fetch failed with token header (\{clip_for_error(header, limit=48)}): exit=\{exit_code.to_string()} err=\{err_text}",
      )
    }
  }
  let (exit_code, out, err) = @process.collect_output("curl", ["-fsSL", url])
  if exit_code == 0 {
    Ok(out.binary().to_array())
  } else {
    let err_text_result = try? err.text()
    let err_text = match err_text_result {
      Ok(v) => clip_for_error(v.trim().to_string())
      Err(_) => "stderr unreadable"
    }
    Err(
      "failed to fetch direct attachment (exit=\{exit_code.to_string()}, err=\{err_text})",
    )
  }
}

///|
async fn fetch_s3_object_bytes(
  state : AppState,
  url : String,
) -> Result[Array[Byte], String] {
  let endpoint = trim_trailing_slash(state.s3_endpoint_url.val)
  if !has_prefix(url, endpoint + "/") {
    return Err("not an allowed s3 endpoint")
  }
  let object_url = substring(url, endpoint.length() + 1, url.length())
  let mut slash_opt : Int? = None
  for i in 0..<object_url.length() {
    if object_url[i] == '/' {
      slash_opt = Some(i)
      break
    }
  }
  let slash = match slash_opt {
    Some(v) => v
    None => return Err("invalid s3 object url")
  }
  if slash <= 0 || slash >= object_url.length() - 1 {
    return Err("invalid s3 object url")
  }
  let bucket = substring(object_url, 0, slash)
  let key = substring(object_url, slash + 1, object_url.length())
  let input_json = "{\"Bucket\":\"" +
    json_escape(bucket) +
    "\",\"Key\":\"" +
    json_escape(key) +
    "\"}"
  let envs : Map[String, String] = {}
  envs.set("AWS_ACCESS_KEY_ID", state.s3_access_key_id.val)
  envs.set("AWS_SECRET_ACCESS_KEY", state.s3_secret_access_key.val)
  envs.set("AWS_REGION", state.s3_region.val)
  envs.set("AWS_DEFAULT_REGION", state.s3_region.val)
  envs.set("AWS_ENDPOINT_URL_S3", state.s3_endpoint_url.val)
  let (exit_code, out) = @process.collect_stdout(
    state.awslim_s3_bin.val,
    ["s3", "get-object", input_json, "--output-stream", "-", "--api-output=false"],
    extra_env=envs,
  )
  if exit_code == 0 {
    Ok(out.binary().to_array())
  } else {
    Err("failed to fetch s3 object")
  }
}

///|
async fn handle_attachment_proxy(
  state : AppState,
  uri : String,
) -> @http.Response {
  let query = parse_query(uri)
  let target_url = match query.get("url") {
    Some(v) => v
    None => return build_response(
      400,
      "Bad Request",
      "missing url query parameter",
      "text/plain; charset=utf-8",
    )
  }
  let download_name = match query.get("name") {
    Some(v) => sanitize_filename(v)
    None => ""
  }
  let wants_inline = match query.get("inline") {
    Some(v) => is_truthy_query(v)
    None => false
  }
  let image_mime = infer_image_mime_from_name(download_name)
  let can_inline = if !wants_inline {
    false
  } else {
    match image_mime {
      Some(_) => true
      None => false
    }
  }
  let content_type = match image_mime {
    Some(m) => if can_inline { m } else { "application/octet-stream" }
    None => "application/octet-stream"
  }
  let content_disposition = if can_inline {
    content_disposition_for_inline(download_name)
  } else {
    content_disposition_for_download(download_name)
  }
  if !is_allowed_proxy_url(state, target_url) {
    return forbidden_response("url is not allowed")
  }
  let target_host = url_host(target_url)
  let is_direct_attachment = target_host == "api.direct4b.com" ||
    target_host == state.direct_attachment_host.val
  if is_direct_attachment {
    match state.attachment_proxy_map.val.get(target_url) {
      Some(mapped_url) => {
        match fetch_s3_object_bytes(state, mapped_url) {
          Ok(body) => return binary_response(
            200,
            "OK",
            body,
            content_type,
            content_disposition=content_disposition,
          )
          Err(err_msg) =>
            println(
              "mapped s3 fetch failed for direct attachment: \{clip_for_error(err_msg)}",
            )
        }
      }
      None => ()
    }
  }
  let fetched = if is_direct_attachment {
    fetch_direct_attachment_bytes(state, target_url)
  } else {
    fetch_s3_object_bytes(state, target_url)
  }
  match fetched {
    Ok(body) => binary_response(
      200,
      "OK",
      body,
      content_type,
      content_disposition=content_disposition,
    )
    Err(msg) => bad_gateway_response(msg)
  }
}

///|
async fn handle_get(state : AppState, uri : String) -> @http.Response {
  let path = path_only(uri)
  if path == "/" {
    return full_page_response(state, None)
  }
  if path == "/attachments/proxy" {
    return handle_attachment_proxy(state, uri)
  }
  if path == "/events" {
    return build_response(
      405, "Method Not Allowed", "Use EventSource GET /events without standard response handler.",
      "text/plain; charset=utf-8",
    )
  }
  if path == "/assets/mhx.js" {
    match read_asset("src/cmd/it_support_app/public/mhx.js") {
      Some(content) => return js_response(content)
      None => return not_found_response()
    }
  }
  let parts = split_path(path)
  if parts.length() == 2 && parts[0] == "tickets" {
    ensure_ticket_open_context(state, parts[1])
    return full_page_response(state, Some(parts[1]))
  }
  if parts.length() == 3 && parts[0] == "partials" && parts[1] == "ticket" {
    let ticket_id = parts[2]
    ensure_ticket_open_context(state, ticket_id)
    let tickets = ticket_view_list(state)
    let ticket = match state.ticket_repo.get(ticket_id) {
      Ok(t) => Some(ticket_for_view(state, t))
      Err(_) => None
    }
    let timeline = match ticket {
      None => []
      Some(t) => state.message_repo.list_public_by_ticket(t.ticket_id)
    }
    let notes = match ticket {
      None => []
      Some(t) =>
        state.message_repo
        .list_workspace_by_ticket(t.ticket_id)
        .filter(fn(m) { m.visibility == @shared.Internal })
    }
    return html_response(
      @web.render_ticket_partial(tickets, ticket, timeline, notes),
    )
  }
  if parts.length() == 3 && parts[0] == "partials" && parts[1] == "tickets" {
    let selected_id = if parts[2] == "-" { None } else { Some(parts[2]) }
    return html_response(
      @web.render_left_partial(ticket_view_list(state), selected_id),
    )
  }
  if parts.length() == 4 &&
    parts[0] == "partials" &&
    parts[1] == "ticket" &&
    parts[3] == "center" {
    let ticket_id = parts[2]
    ensure_ticket_open_context(state, ticket_id)
    let ticket = match state.ticket_repo.get(ticket_id) {
      Ok(t) => Some(ticket_for_view(state, t))
      Err(_) => None
    }
    let timeline = match ticket {
      None => []
      Some(t) => state.message_repo.list_public_by_ticket(t.ticket_id)
    }
    return html_response(@web.render_center_partial(ticket, timeline, None))
  }
  if parts.length() == 4 &&
    parts[0] == "partials" &&
    parts[1] == "ticket" &&
    parts[3] == "right" {
    let ticket_id = parts[2]
    ensure_ticket_open_context(state, ticket_id)
    let ticket = match state.ticket_repo.get(ticket_id) {
      Ok(t) => Some(ticket_for_view(state, t))
      Err(_) => None
    }
    let notes = match ticket {
      None => []
      Some(t) =>
        state.message_repo
        .list_workspace_by_ticket(t.ticket_id)
        .filter(fn(m) { m.visibility == @shared.Internal })
    }
    return html_response(@web.render_right_partial(ticket, notes, None))
  }
  not_found_response()
}

///|
fn handle_post(
  state : AppState,
  path : String,
  body : Array[Byte],
  mhx_request : Bool,
) -> @http.Response {
  let parts = split_path(path)
  if parts.length() == 2 && parts[0] == "tickets" && parts[1] == "close" {
    let form = parse_form(body_to_string(body))
    let selected_ticket_id = match form.get("selected_ticket_id") {
      Some(v) => if v == "-" { None } else { Some(v) }
      None => None
    }
    let ticket_ids_csv = match form.get("ticket_ids_csv") {
      Some(v) => v
      None => ""
    }
    let now = @env.now().to_string()
    for id_view in ticket_ids_csv.split(",") {
      let ticket_id = id_view.to_string().trim().to_string()
      if ticket_id == "" {
        continue
      }
      match state.ticket_repo.get(ticket_id) {
        Ok(ticket) => {
          if ticket.status == @shared.Closed {
            continue
          }
          let updated = @shared.Ticket::{
            ..ticket,
            status: @shared.Closed,
            updated_at: now,
          }
          match state.ticket_repo.update(updated) {
            Ok(_) => notify_ticket_updated(state, ticket_id)
            Err(_) => ()
          }
        }
        Err(_) => ()
      }
    }
    if mhx_request {
      return html_response(
        @web.render_left_partial(ticket_view_list(state), selected_ticket_id),
      )
    }
    match selected_ticket_id {
      Some(ticket_id) => return redirect_to_ticket(ticket_id)
      None => return full_page_response(state, None)
    }
  }
  if parts.length() == 5 && parts[0] == "tickets" && parts[2] == "notes" {
    let ticket_id = parts[1]
    let message_id = parts[3]
    let note_action = parts[4]
    let form = parse_form(body_to_string(body))
    let intent = match form.get("intent") {
      Some(v) => v
      None => ""
    }
    let ticket = match state.ticket_repo.get(ticket_id) {
      Ok(t) => Some(t)
      Err(_) => None
    }
    let notes = state.message_repo
      .list_workspace_by_ticket(ticket_id)
      .filter(fn(m) { m.visibility == @shared.Internal })
    let is_closed_ticket = match ticket {
      Some(t) => t.status == @shared.Closed
      None => false
    }
    if is_closed_ticket {
      return closed_ticket_response(mhx_request, "right", ticket, [], notes)
    }
    if intent == "reply" {
      if mhx_request {
        return html_error_response(
          422,
          "Unprocessable Entity",
          @web.render_right_partial(
            ticket,
            notes,
            Some("Invalid form intent for note."),
          ),
        )
      }
      return build_response(
        422, "Unprocessable Entity", "Invalid form intent for note.", "text/plain; charset=utf-8",
      )
    }
    match state.message_repo.get(message_id) {
      Err(_) => {
        let notes2 = state.message_repo
          .list_workspace_by_ticket(ticket_id)
          .filter(fn(m) { m.visibility == @shared.Internal })
        if mhx_request {
          return html_response(@web.render_right_partial(ticket, notes2, None))
        }
        return redirect_to_ticket(ticket_id)
      }
      Ok(note_message) => {
        if note_message.ticket_id != ticket_id ||
          note_message.visibility != @shared.Internal {
          let notes2 = state.message_repo
            .list_workspace_by_ticket(ticket_id)
            .filter(fn(m) { m.visibility == @shared.Internal })
          if mhx_request {
            return html_response(
              @web.render_right_partial(ticket, notes2, None),
            )
          }
          return redirect_to_ticket(ticket_id)
        }
        match note_action {
          "edit" => {
            let text = match form.get("note_text") {
              Some(v) => v
              None => ""
            }
            if is_blank_text(text) {
              if mhx_request {
                return html_error_response(
                  422,
                  "Unprocessable Entity",
                  @web.render_right_partial(
                    ticket,
                    notes,
                    Some("Note text is required."),
                  ),
                )
              }
              return build_response(
                422, "Unprocessable Entity", "Note text is required.", "text/plain; charset=utf-8",
              )
            }
            let updated = @shared.Message::{ ..note_message, text, }
            let _ = state.message_repo.update(updated)
            notify_ticket_updated(state, ticket_id)
            let notes2 = state.message_repo
              .list_workspace_by_ticket(ticket_id)
              .filter(fn(m) { m.visibility == @shared.Internal })
            if mhx_request {
              return html_response(
                @web.render_right_partial(ticket, notes2, None),
              )
            }
            return redirect_to_ticket(ticket_id)
          }
          "delete" => {
            match state.message_repo.delete(message_id) {
              Err(_) => {
                let notes2 = state.message_repo
                  .list_workspace_by_ticket(ticket_id)
                  .filter(fn(m) { m.visibility == @shared.Internal })
                if mhx_request {
                  return html_response(
                    @web.render_right_partial(ticket, notes2, None),
                  )
                }
                return redirect_to_ticket(ticket_id)
              }
              Ok(_) => notify_ticket_updated(state, ticket_id)
            }
            let notes2 = state.message_repo
              .list_workspace_by_ticket(ticket_id)
              .filter(fn(m) { m.visibility == @shared.Internal })
            if mhx_request {
              return html_response(
                @web.render_right_partial(ticket, notes2, None),
              )
            }
            return redirect_to_ticket(ticket_id)
          }
          _ => return not_found_response()
        }
      }
    }
  }
  if parts.length() == 3 && parts[0] == "tickets" {
    let ticket_id = parts[1]
    let action = parts[2]
    let form = parse_form(body_to_string(body))
    let intent = match form.get("intent") {
      Some(v) => v
      None => ""
    }
    match action {
      "reply" => {
        let text = match form.get("reply_text") {
          Some(v) => v
          None => ""
        }
        let ticket = match state.ticket_repo.get(ticket_id) {
          Ok(t) => Some(t)
          Err(_) => None
        }
        let timeline = state.message_repo.list_public_by_ticket(ticket_id)
        let is_closed_ticket = match ticket {
          Some(t) => t.status == @shared.Closed
          None => false
        }
        if is_closed_ticket {
          return closed_ticket_response(
            mhx_request,
            "center",
            ticket,
            timeline,
            [],
          )
        }
        if intent == "note" {
          if mhx_request {
            return html_error_response(
              422,
              "Unprocessable Entity",
              @web.render_center_partial(
                ticket,
                timeline,
                Some("Invalid form intent for reply."),
              ),
            )
          }
          return build_response(
            422, "Unprocessable Entity", "Invalid form intent for reply.", "text/plain; charset=utf-8",
          )
        }
        if is_blank_text(text) {
          if mhx_request {
            return html_error_response(
              422,
              "Unprocessable Entity",
              @web.render_center_partial(
                ticket,
                timeline,
                Some("Reply text is required."),
              ),
            )
          }
          return build_response(
            422, "Unprocessable Entity", "Reply text is required.", "text/plain; charset=utf-8",
          )
        }
        let msg = @shared.Message::new(
          next_id(state.id_counter, "msg"),
          ticket_id,
          text,
          @shared.Public,
          @shared.Console,
          "support",
        )
        let _ = state.message_repo.create(@shared.Message::{
          ..msg,
          sender_name: "Support",
        })
        match ticket {
          Some(t) =>
            enqueue_direct_outbound(
              state,
              t,
              text,
              "outbound:" + msg.message_id,
            )
          None => ()
        }
        notify_ticket_updated(state, ticket_id)
        let timeline2 = state.message_repo.list_public_by_ticket(ticket_id)
        if mhx_request {
          return html_response(
            @web.render_center_partial(ticket, timeline2, None),
          )
        }
        return redirect_to_ticket(ticket_id)
      }
      "notes" => {
        let text = match form.get("note_text") {
          Some(v) => v
          None => ""
        }
        let ticket = match state.ticket_repo.get(ticket_id) {
          Ok(t) => Some(t)
          Err(_) => None
        }
        let notes = state.message_repo
          .list_workspace_by_ticket(ticket_id)
          .filter(fn(m) { m.visibility == @shared.Internal })
        let is_closed_ticket = match ticket {
          Some(t) => t.status == @shared.Closed
          None => false
        }
        if is_closed_ticket {
          return closed_ticket_response(mhx_request, "right", ticket, [], notes)
        }
        if intent == "reply" {
          if mhx_request {
            return html_error_response(
              422,
              "Unprocessable Entity",
              @web.render_right_partial(
                ticket,
                notes,
                Some("Invalid form intent for note."),
              ),
            )
          }
          return build_response(
            422, "Unprocessable Entity", "Invalid form intent for note.", "text/plain; charset=utf-8",
          )
        }
        if is_blank_text(text) {
          if mhx_request {
            return html_error_response(
              422,
              "Unprocessable Entity",
              @web.render_right_partial(
                ticket,
                notes,
                Some("Note text is required."),
              ),
            )
          }
          return build_response(
            422, "Unprocessable Entity", "Note text is required.", "text/plain; charset=utf-8",
          )
        }
        let msg = @shared.Message::new_note(
          next_id(state.id_counter, "note"),
          ticket_id,
          text,
          "support",
        )
        let _ = state.message_repo.create(@shared.Message::{
          ..msg,
          sender_name: "Support",
        })
        notify_ticket_updated(state, ticket_id)
        let notes2 = state.message_repo
          .list_workspace_by_ticket(ticket_id)
          .filter(fn(m) { m.visibility == @shared.Internal })
        if mhx_request {
          return html_response(@web.render_right_partial(ticket, notes2, None))
        }
        return redirect_to_ticket(ticket_id)
      }
      _ => ()
    }
  }
  not_found_response()
}

///|
async fn build_response_for_request(
  state : AppState,
  request : @http.Request,
) -> @http.Response {
  let path = path_only(request.uri)
  let mhx_request = is_mhx_request(request)
  match request.http_method {
    "GET" => handle_get(state, request.uri)
    "POST" => handle_post(state, path, request.body, mhx_request)
    _ =>
      build_response(405, "Method Not Allowed", "", "text/plain; charset=utf-8")
  }
}

///|
fn try_bind_server(port : Int) -> @socket.TcpServer? {
  let addr = "0.0.0.0:" + port.to_string()
  let result : Result[@socket.TcpServer, Error] = try? @socket.TcpServer::new(
    @socket.Addr::parse(addr),
    reuse_addr=true,
  )
  match result {
    Ok(server) => Some(server)
    Err(_) => None
  }
}

///|
fn bind_first_available_port(
  start_port : Int,
  max_attempts : Int,
) -> (@socket.TcpServer, Int)? {
  for offset in 0..<max_attempts {
    let port = start_port + offset
    match try_bind_server(port) {
      Some(server) => return Some((server, port))
      None => ()
    }
  }
  None
}

///|
struct DirectStartupConfig {
  token : String
  bot_user_id : String
  platform : String
  endpoint : String
  proxy_url : String
}

///|
fn has_prefix(text : String, prefix : String) -> Bool {
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
fn contains_text(text : String, pattern : String) -> Bool {
  if pattern == "" {
    return true
  }
  if text.length() < pattern.length() {
    return false
  }
  for start in 0..<(text.length() - pattern.length() + 1) {
    let mut matched = true
    for i in 0..<pattern.length() {
      if text[start + i] != pattern[i] {
        matched = false
        break
      }
    }
    if matched {
      return true
    }
  }
  false
}

///|
fn has_flag(args : Array[String], key : String) -> Bool {
  let flag = "--" + key
  for arg in args {
    if arg == flag {
      return true
    }
  }
  false
}

///|
fn arg_value(args : Array[String], key : String) -> String? {
  let prefix = "--" + key + "="
  for arg in args {
    if has_prefix(arg, prefix) {
      let sb = StringBuilder::new(size_hint=arg.length())
      for i in prefix.length()..<arg.length() {
        sb.write_char(arg[i].unsafe_to_char())
      }
      return Some(sb.to_string())
    }
  }
  None
}

///|
fn trim_trailing_newlines(value : String) -> String {
  let mut end = value.length()
  while end > 0 {
    let c = value[end - 1]
    if c == '\n' || c == '\r' {
      end = end - 1
    } else {
      break
    }
  }
  let sb = StringBuilder::new(size_hint=end)
  for i in 0..<end {
    sb.write_char(value[i].unsafe_to_char())
  }
  sb.to_string()
}

///|
async fn env_value(name : String) -> String {
  let (exit_code, stdout) = @process.collect_stdout("printenv", [name])
  if exit_code != 0 {
    return ""
  }
  let text = try? stdout.text()
  match text {
    Ok(v) => trim_trailing_newlines(v)
    Err(_) => ""
  }
}

///|
async fn read_direct_startup_config() -> DirectStartupConfig {
  let args = @env.args()
  let token_from_env_primary = env_value("DIRECT4B_API_TOKEN")
  let token_from_env_hubot = env_value("HUBOT_DIRECT_TOKEN")
  let bot_user_id_from_env = env_value("DIRECT4B_BOT_USER_ID")
  let platform_from_env = env_value("DIRECT4B_PLATFORM")
  let endpoint_from_env_primary = env_value("DIRECT4B_ENDPOINT")
  let endpoint_from_env_hubot = env_value("HUBOT_DIRECT_ENDPOINT")
  let proxy_url_from_env_primary = env_value("DIRECT4B_PROXY_URL")
  let proxy_url_from_env_hubot = env_value("HUBOT_DIRECT_PROXY_URL")

  let token = if token_from_env_primary != "" {
    token_from_env_primary
  } else if token_from_env_hubot != "" {
    token_from_env_hubot
  } else {
    match arg_value(args, "direct-token") {
      Some(v) => v
      None => ""
    }
  }
  let bot_user_id = if bot_user_id_from_env != "" {
    bot_user_id_from_env
  } else {
    match arg_value(args, "direct-bot-user-id") {
      Some(v) => v
      None => ""
    }
  }
  let platform = if platform_from_env != "" {
    platform_from_env
  } else {
    match arg_value(args, "direct-platform") {
      Some(v) => if v == "" { "direct4b" } else { v }
      None => "direct4b"
    }
  }
  let endpoint = if endpoint_from_env_primary != "" {
    endpoint_from_env_primary
  } else if endpoint_from_env_hubot != "" {
    endpoint_from_env_hubot
  } else {
    match arg_value(args, "direct-endpoint") {
      Some(v) => v
      None => ""
    }
  }
  let proxy_url = if proxy_url_from_env_primary != "" {
    proxy_url_from_env_primary
  } else if proxy_url_from_env_hubot != "" {
    proxy_url_from_env_hubot
  } else {
    match arg_value(args, "direct-proxy-url") {
      Some(v) => v
      None => ""
    }
  }
  { token, bot_user_id, platform, endpoint, proxy_url }
}

///|
fn build_ingest_context(state : AppState) -> @core.IngestContext {
  @core.IngestContext::new(
    state.ticket_repo,
    state.message_repo,
    fn() { next_id(state.id_counter, "id") },
    fn() { @env.now().to_string() },
  )
}

///|
fn first_non_empty_line(text : String) -> String {
  for line in text.split("\n") {
    let trimmed = line.to_string().trim().to_string()
    if trimmed != "" {
      return trimmed
    }
  }
  ""
}

///|
fn append_lines(base : String, lines : Array[String]) -> String {
  if lines.is_empty() {
    return base
  }
  let suffix = lines.join("\n")
  if base == "" {
    suffix
  } else {
    base + "\n" + suffix
  }
}

///|
fn strip_plain_file_lines(
  base : String,
  attachments : Array[@shared.Attachment],
) -> String {
  if base == "" || attachments.is_empty() {
    return base
  }
  let kept : Array[String] = []
  for raw_line in base.split("\n") {
    let line = raw_line.to_string()
    let trimmed = line.trim().to_string()
    let mut drop = trimmed == "[file]"
    if !drop {
      for attachment in attachments {
        if trimmed == "[file] " + attachment.name {
          drop = true
          break
        }
      }
    }
    if !drop {
      kept.push(line)
    }
  }
  kept.join("\n")
}

///|
async fn upload_attachment_url_with_hook(
  state : AppState,
  normalized : @adapters.NormalizedMessage,
  attachment : @shared.Attachment,
) -> String? {
  let command = state.attachment_upload_cmd.val.trim().to_string()
  if command == "" || attachment.url == "" {
    return None
  }
  let source_url = attachment.url
  let envs : Map[String, String] = {}
  envs.set("AIRLOCK_ATTACHMENT_URL", source_url)
  envs.set("AIRLOCK_ATTACHMENT_DOWNLOAD_URL", source_url)
  envs.set("AIRLOCK_ATTACHMENT_NAME", attachment.name)
  envs.set("AIRLOCK_ATTACHMENT_TYPE", attachment.attachment_type.to_string())
  envs.set("AIRLOCK_MESSAGE_EXTERNAL_ID", normalized.external_id)
  envs.set("AIRLOCK_CHANNEL_ID", normalized.channel_id)
  envs.set("AIRLOCK_PLATFORM", normalized.platform)
  if state.direct_api_token.val != "" {
    envs.set("DIRECT4B_API_TOKEN", state.direct_api_token.val)
    envs.set("DIRECT_API_TOKEN", state.direct_api_token.val)
  }
  let (exit_code, stdout) = @process.collect_stdout(
    "sh",
    ["-c", command],
    extra_env=envs,
  )
  if exit_code != 0 {
    return None
  }
  let out_text_result = try? stdout.text()
  let out_text = match out_text_result {
    Ok(v) => v
    Err(_) => ""
  }
  let uploaded_url = first_non_empty_line(out_text)
  if uploaded_url == "" {
    None
  } else {
    Some(uploaded_url)
  }
}

///|
async fn rewrite_attachment_urls(
  state : AppState,
  normalized : @adapters.NormalizedMessage,
) -> @adapters.NormalizedMessage {
  if normalized.attachments.is_empty() {
    return normalized
  }
  let hook_enabled = state.attachment_upload_cmd.val.trim().to_string() != ""
  let rewritten : Array[@shared.Attachment] = []
  let attachment_lines : Array[String] = []
  let mut failed = 0
  for attachment in normalized.attachments {
    let original_url = attachment.url
    let final_attachment = match
      upload_attachment_url_with_hook(state, normalized, attachment) {
      Some(url) => {
        if has_prefix(
          original_url,
          "https://api.direct4b.com/albero-app-server/files/",
        ) {
          state.attachment_proxy_map.val.set(original_url, url)
        }
        @shared.Attachment::{
          ..attachment,
          url: "/attachments/proxy?url=" +
            url_encode_component(url) +
            "&name=" +
            url_encode_component(attachment.name),
        }
      }
      None => {
        if hook_enabled {
          failed = failed + 1
        }
        if original_url != "" {
          @shared.Attachment::{
            ..attachment,
            url: "/attachments/proxy?url=" +
              url_encode_component(original_url) +
              "&name=" +
              url_encode_component(attachment.name),
          }
        } else {
          attachment
        }
      }
    }
    rewritten.push(final_attachment)
    if final_attachment.url != "" &&
      final_attachment.attachment_type != @shared.Image {
      attachment_lines.push(
        "[file] " + final_attachment.name + " " + final_attachment.url,
      )
    }
  }
  let base_text = strip_plain_file_lines(normalized.text, rewritten)
  let lines = attachment_lines
  if failed > 0 && hook_enabled {
    lines.push("[attachment-upload-failed] count=" + failed.to_string())
  }
  @adapters.NormalizedMessage::{
    ..normalized,
    attachments: rewritten,
    text: append_lines(base_text, lines),
  }
}

///|
async fn handle_direct_incoming_async(
  state : AppState,
  ingest_ctx : @core.IngestContext,
  normalized : @adapters.NormalizedMessage,
) -> Unit {
  let normalized = rewrite_attachment_urls(state, normalized)
  let normalized = if state.dev_mode.val && normalized.raw_data != "" {
    @adapters.NormalizedMessage::{ ..normalized, text: normalized.raw_data }
  } else {
    normalized
  }
  if normalized.sender_id != "" &&
    normalized.sender_name != "" &&
    normalized.sender_name != normalized.sender_id {
    state.direct_user_name_cache.val.set(
      normalized.sender_id,
      normalized.sender_name,
    )
  }
  if consume_outbound_echo(state, normalized.channel_id, normalized.text) {
    println(
      "ignored outbound echo from direct: channel=\{normalized.channel_id}",
    )
    return
  }
  match @core.ingest_incoming(ingest_ctx, normalized.to_inbound()) {
    Ok(@core.Created(ticket_id, message_id)) => {
      notify_ticket_updated(state, ticket_id)
      println(
        "ingested direct message: ticket=\{ticket_id}, message=\{message_id}",
      )
    }
    Ok(@core.DuplicateIgnored(ticket_id, message_id)) => {
      notify_ticket_updated(state, ticket_id)
      println(
        "ignored duplicated direct message: ticket=\{ticket_id}, message=\{message_id}",
      )
    }
    Err(err) => println("failed to ingest direct message: \{err.to_string()}")
  }
}

///|
async fn try_start_direct_bridge(
  state : AppState,
  ingest_ctx : @core.IngestContext,
  tasks : @async.TaskGroup[Unit],
) -> Unit {
  let cfg = read_direct_startup_config()
  println(
    "direct bridge config: endpoint=\{cfg.endpoint} proxy=\{cfg.proxy_url} token_len=\{cfg.token.length().to_string()} bot_user_id=\{cfg.bot_user_id}",
  )
  state.direct_api_token.val = cfg.token
  let endpoint_host = url_host(cfg.endpoint)
  if endpoint_host != "" {
    state.direct_attachment_host.val = endpoint_host
  }
  if cfg.token == "" || cfg.bot_user_id == "" {
    println(
      "direct bridge disabled: set DIRECT4B_API_TOKEN and DIRECT4B_BOT_USER_ID",
    )
    return
  }
  let adapter_cfg = @adapters.AdapterConfig::new(
    cfg.platform,
    cfg.bot_user_id,
    cfg.token,
  )
  let adapter = @adapters.DirectAdapter::new(
    adapter_cfg,
    endpoint=cfg.endpoint,
    proxy_url=cfg.proxy_url,
  )
  adapter.listen_incoming(fn(normalized) {
    if mark_seen_direct_external_id(state, normalized.external_id) {
      println("ignored duplicated direct event: id=\{normalized.external_id}")
      return
    }
    tasks.spawn_bg(() => {
      handle_direct_incoming_async(state, ingest_ctx, normalized)
    })
  })
  match adapter.connect(tasks) {
    Ok(_) => {
      state.direct_adapter.val = Some(adapter)
      state.direct_user_names_loaded.val = false
      println(
        "direct bridge connected (platform=\{cfg.platform}, bot_user_id=\{cfg.bot_user_id})",
      )
    }
    Err(err) => println("direct bridge connect failed: \{err.to_string()}")
  }
}

///|
async fn main {
  let state = seed_state()
  let args = @env.args()
  state.dev_mode.val = has_flag(args, "dev")
  if state.dev_mode.val {
    println("dev mode enabled: timeline renders raw_data when available")
  }
  state.direct_api_token.val = env_value("DIRECT4B_API_TOKEN")
  let s3_endpoint = env_value("S3_ENDPOINT_URL")
  if s3_endpoint != "" {
    state.s3_endpoint_url.val = s3_endpoint
  }
  let awslim_bin = env_value("AWSLIM_S3_BIN")
  if awslim_bin != "" {
    state.awslim_s3_bin.val = awslim_bin
  }
  let s3_access_key_id = env_value("AWS_ACCESS_KEY_ID")
  if s3_access_key_id != "" {
    state.s3_access_key_id.val = s3_access_key_id
  }
  let s3_secret_access_key = env_value("AWS_SECRET_ACCESS_KEY")
  if s3_secret_access_key != "" {
    state.s3_secret_access_key.val = s3_secret_access_key
  }
  let s3_region = {
    let region = env_value("AWS_REGION")
    if region != "" {
      region
    } else {
      env_value("AWS_DEFAULT_REGION")
    }
  }
  if s3_region != "" {
    state.s3_region.val = s3_region
  }
  let attachment_upload_cmd_env = env_value("AIRLOCK_ATTACHMENT_UPLOAD_CMD")
  let attachment_upload_cmd_arg = match arg_value(args, "attachment-upload-cmd") {
    Some(v) => v.trim().to_string()
    None => ""
  }
  let enable_attachment_upload_s3 = has_flag(args, "attachment-upload-s3")
  state.attachment_upload_cmd.val = if attachment_upload_cmd_arg != "" {
    attachment_upload_cmd_arg
  } else if attachment_upload_cmd_env != "" {
    attachment_upload_cmd_env
  } else if enable_attachment_upload_s3 {
    "./src/cmd/it_support_app/scripts/upload_to_s3_compatible.sh"
  } else {
    ""
  }
  if state.attachment_upload_cmd.val.trim().to_string() != "" {
    println(
      "attachment upload hook enabled: cmd=\{state.attachment_upload_cmd.val}",
    )
  }
  let ingest_ctx = build_ingest_context(state)
  @async.with_task_group(async fn(tasks) {
    tasks.spawn_bg(() => process_outbound_queue_loop(state))
    tasks.spawn_bg(() => maintain_direct_bridge_loop(state, ingest_ctx, tasks))
    match bind_first_available_port(8080, 50) {
      Some((server, port)) => {
        println(
          "it-support-app listening on http://0.0.0.0:" + port.to_string(),
        )
        server.run_forever(async fn(conn, _peer_addr) {
          let decoder = @http.RequestDecoder::new()
          while conn.read_some() is Some(data) {
            match decoder.feed(bytes_to_array(data)) {
              Err(_) => {
                let response_str = "HTTP/1.1 400 Bad Request\r\nContent-Length: 11\r\nConnection: close\r\n\r\nBad Request"
                conn.write(array_to_bytes(string_to_bytes(response_str)))
                return
              }
              Ok(_) => ()
            }
            match decoder.decode() {
              Ok(Some(request)) => {
                let path = path_only(request.uri)
                if request.http_method == "GET" && path == "/events" {
                  handle_sse_subscribe(state, conn)
                  return
                }
                let response = build_response_for_request(state, request)
                let response_bytes = @http.encode_response(response)
                conn.write(array_to_bytes(response_bytes))
                return
              }
              Ok(None) | Err(@http.HttpError::UnexpectedEof) => ()
              Err(_) => {
                let response_str = "HTTP/1.1 400 Bad Request\r\nContent-Length: 11\r\nConnection: close\r\n\r\nBad Request"
                conn.write(array_to_bytes(string_to_bytes(response_str)))
                return
              }
            }
          }
        })
      }
      None =>
        println("failed to bind server: no available port in range 8080..8129")
    }
  })
}
