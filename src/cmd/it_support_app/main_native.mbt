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
  { ticket_repo, message_repo, id_counter }
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
fn full_page_response(
  state : AppState,
  preferred_ticket_id : String?,
) -> @http.Response {
  let tickets = state.ticket_repo.list()
  let selected = match preferred_ticket_id {
    Some(ticket_id) =>
      match state.ticket_repo.get(ticket_id) {
        Ok(t) => Some(t)
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
fn handle_get(state : AppState, path : String) -> @http.Response {
  if path == "/" {
    return full_page_response(state, None)
  }
  if path == "/assets/mhx.js" {
    match read_asset("src/cmd/it_support_app/public/mhx.js") {
      Some(content) => return js_response(content)
      None => return not_found_response()
    }
  }
  let parts = split_path(path)
  if parts.length() == 2 && parts[0] == "tickets" {
    return full_page_response(state, Some(parts[1]))
  }
  if parts.length() == 3 && parts[0] == "partials" && parts[1] == "ticket" {
    let ticket_id = parts[2]
    let tickets = state.ticket_repo.list()
    let ticket = match state.ticket_repo.get(ticket_id) {
      Ok(t) => Some(t)
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
              Ok(_) => ()
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
        let _ = state.message_repo.create(msg)
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
        let _ = state.message_repo.create(msg)
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
fn build_response_for_request(
  state : AppState,
  request : @http.Request,
) -> @http.Response {
  let path = path_only(request.uri)
  let mhx_request = is_mhx_request(request)
  match request.http_method {
    "GET" => handle_get(state, path)
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
  let token_from_env = env_value("DIRECT4B_API_TOKEN")
  let bot_user_id_from_env = env_value("DIRECT4B_BOT_USER_ID")
  let platform_from_env = env_value("DIRECT4B_PLATFORM")
  let endpoint_from_env = env_value("DIRECT4B_ENDPOINT")
  let proxy_url_from_env = env_value("DIRECT4B_PROXY_URL")

  let token = if token_from_env != "" {
    token_from_env
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
  let endpoint = if endpoint_from_env != "" {
    endpoint_from_env
  } else {
    match arg_value(args, "direct-endpoint") {
      Some(v) => v
      None => ""
    }
  }
  let proxy_url = if proxy_url_from_env != "" {
    proxy_url_from_env
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
fn handle_direct_incoming(
  ingest_ctx : @core.IngestContext,
  normalized : @adapters.NormalizedMessage,
) -> Unit {
  match @core.ingest_incoming(ingest_ctx, normalized.to_inbound()) {
    Ok(@core.Created(ticket_id, message_id)) =>
      println(
        "ingested direct message: ticket=\{ticket_id}, message=\{message_id}",
      )
    Ok(@core.DuplicateIgnored(ticket_id, message_id)) =>
      println(
        "ignored duplicated direct message: ticket=\{ticket_id}, message=\{message_id}",
      )
    Err(err) => println("failed to ingest direct message: \{err.to_string()}")
  }
}

///|
async fn try_start_direct_bridge(
  ingest_ctx : @core.IngestContext,
  tasks : @async.TaskGroup[Unit],
) -> Unit {
  let cfg = read_direct_startup_config()
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
    handle_direct_incoming(ingest_ctx, normalized)
  })
  match adapter.connect(tasks) {
    Ok(_) =>
      println(
        "direct bridge connected (platform=\{cfg.platform}, bot_user_id=\{cfg.bot_user_id})",
      )
    Err(err) => println("direct bridge connect failed: \{err.to_string()}")
  }
}

///|
async fn main {
  let state = seed_state()
  let ingest_ctx = build_ingest_context(state)
  @async.with_task_group(async fn(tasks) {
    try_start_direct_bridge(ingest_ctx, tasks)
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
