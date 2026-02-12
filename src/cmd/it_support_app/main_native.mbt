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
  let mut result = ""
  for b in body {
    result = result + Int::unsafe_to_char(b.to_int()).to_string()
  }
  result
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
fn hex_val_byte(b : Byte) -> Int? {
  let code = b.to_int()
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
fn url_decode(input : String) -> String {
  let raw = @utf8.encode(input)
  let bytes : Array[Byte] = []
  let percent = Int::to_byte(37)
  let plus = Int::to_byte(43)
  let mut i = 0
  while i < raw.length() {
    let b = raw[i]
    if b == percent && i + 2 < raw.length() {
      match (hex_val_byte(raw[i + 1]), hex_val_byte(raw[i + 2])) {
        (Some(hi), Some(lo)) => {
          bytes.push(Int::to_byte(hi * 16 + lo))
          i = i + 3
        }
        _ => {
          bytes.push(b)
          i = i + 1
        }
      }
    } else if b == plus {
      bytes.push(Int::to_byte(32))
      i = i + 1
    } else {
      bytes.push(b)
      i = i + 1
    }
  }
  @utf8.decode_lossy(Bytes::from_array(bytes))
}

///|
fn parse_form(body : String) -> Map[String, String] {
  let result : Map[String, String] = {}
  if body == "" {
    return result
  }
  for pair_view in body.split("&") {
    let iter = pair_view.to_string().split("=")
    let key_view = iter.next()
    let value_view = iter.next()
    match key_view {
      None => ()
      Some(kv) => {
        let key = kv.to_string()
        let value = match value_view {
          Some(v) => v.to_string()
          None => ""
        }
        result.set(url_decode(key), url_decode(value))
      }
    }
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
  if parts.length() == 3 && parts[0] == "tickets" {
    let ticket_id = parts[1]
    let action = parts[2]
    let form = parse_form(body_to_string(body))
    let text = match form.get("text") {
      Some(v) => v
      None => ""
    }
    match action {
      "reply" => {
        let ticket = match state.ticket_repo.get(ticket_id) {
          Ok(t) => Some(t)
          Err(_) => None
        }
        let timeline = state.message_repo.list_public_by_ticket(ticket_id)
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
          return full_page_response(state, Some(ticket_id))
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
        return full_page_response(state, Some(ticket_id))
      }
      "notes" => {
        let ticket = match state.ticket_repo.get(ticket_id) {
          Ok(t) => Some(t)
          Err(_) => None
        }
        let notes = state.message_repo
          .list_workspace_by_ticket(ticket_id)
          .filter(fn(m) { m.visibility == @shared.Internal })
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
          return full_page_response(state, Some(ticket_id))
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
        return full_page_response(state, Some(ticket_id))
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
async fn main {
  let state = seed_state()
  match bind_first_available_port(8080, 50) {
    Some((server, port)) => {
      println("it-support-app listening on http://0.0.0.0:" + port.to_string())
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
}
