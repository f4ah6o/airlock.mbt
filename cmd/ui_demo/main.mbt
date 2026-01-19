///|
using @element {button, div, events, h2, p, text}

///|
fn demo_styles() -> String {
  let lines : Array[String] = [
    "html, body {", "  margin: 0;", "  padding: 0;", "  height: 100%;", "  font-family: \"Space Grotesk\", \"Noto Sans JP\", \"Segoe UI\", sans-serif;",
    "}", "#app {", "  height: 100%;", "}", ".airlock-demo {", "  display: grid;",
    "  grid-template-columns: minmax(0, 1.1fr) minmax(0, 1.1fr) minmax(0, 0.9fr);",
    "  gap: 18px;", "  height: 100%;", "  padding: 20px;", "  box-sizing: border-box;",
    "  background: radial-gradient(circle at top, #ffffff 0%, #fdf4e7 45%, #f8f9fb 100%);",
    "}", ".airlock-demo__pane {", "  display: flex;", "  flex-direction: column;",
    "  min-height: 0;", "}", ".airlock-demo__header {", "  display: flex;", "  flex-direction: column;",
    "  gap: 4px;", "  margin-bottom: 12px;", "}", ".airlock-demo__title {", "  margin: 0;",
    "  font-size: 18px;", "  letter-spacing: 0.02em;", "}", ".airlock-demo__subtitle {",
    "  margin: 0;", "  color: #6b7280;", "  font-size: 13px;", "}", ".airlock-demo__chat {",
    "  flex: 1;", "  min-height: 0;", "  display: flex;", "  flex-direction: column;",
    "  gap: 12px;", "}", ".airlock-demo__log {", "  flex: 1;", "  min-height: 0;",
    "  border-radius: 12px;", "  border: 1px solid rgba(15, 23, 42, 0.12);", "  background: #ffffff;",
    "  padding: 12px;", "  overflow: auto;", "}", ".airlock-demo__log-content {",
    "  font-family: \"JetBrains Mono\", ui-monospace, monospace;", "  font-size: 12px;",
    "  line-height: 1.6;", "  color: #111827;", "  white-space: pre-wrap;", "}",
    ".airlock-demo__controls {", "  display: flex;", "  justify-content: flex-end;",
    "  gap: 8px;", "}", ".airlock-demo__chat .airlock-moonchat {", "  flex: 1;",
    "  height: auto;", "}", "@media (max-width: 900px) {", "  .airlock-demo {", "    grid-template-columns: 1fr;",
    "  }", "}",
    ".airlock-input-area {",
    "  display: flex;",
    "  gap: 8px;",
    "  padding: 12px;",
    "  background: #ffffff;",
    "  border-radius: 8px;",
    "  border: 1px solid rgba(15, 23, 42, 0.12);",
    "}",
    ".airlock-input-field {",
    "  flex: 1;",
    "  padding: 8px 12px;",
    "  border: 1px solid rgba(15, 23, 42, 0.2);",
    "  border-radius: 6px;",
    "  font-size: 14px;",
    "  outline: none;",
    "}",
    ".airlock-input-field:focus {",
    "  border-color: #3b82f6;",
    "}",
    ".airlock-input-button {",
    "  padding: 8px 16px;",
    "  background: #3b82f6;",
    "  color: white;",
    "  border: none;",
    "  border-radius: 6px;",
    "  cursor: pointer;",
    "  font-size: 14px;",
    "}",
    ".airlock-input-button:hover {",
    "  background: #2563eb;",
    "}",
    ".airlock-input-button:disabled {",
    "  background: #9ca3af;",
    "  cursor: not-allowed;",
    "}",
    ".airlock-input-field:disabled {",
    "  background: #f3f4f6;",
    "}",
  ]
  lines.join("\n")
}

///|
fn inject_styles(css : String) -> Unit {
  let doc = @js_dom.document()
  let style = doc.createElement("style")
  style.setTextContent(css)
  match doc.head() {
    Some(head) => head.as_node().appendChild(style.as_node()) |> ignore
    None =>
      match doc.body() {
        Some(body) => body.as_node().appendChild(style.as_node()) |> ignore
        None => ()
      }
  }
}

///|
fn ensure_root(id : String) -> @element.DomElement {
  let doc = @js_dom.document()
  match doc.getElementById(id) {
    Some(existing) => @element.DomElement::from_dom(existing)
    None => {
      let root = doc.createElement("div")
      root.setId(id)
      match doc.body() {
        Some(body) => body.as_node().appendChild(root.as_node()) |> ignore
        None => ()
      }
      @element.DomElement::from_dom(root)
    }
  }
}

///|
fn next_message_id(counter : Ref[Int], prefix : String) -> String {
  counter.val = counter.val + 1
  prefix + "-" + counter.val.to_string()
}

///|
fn next_timestamp(counter : Ref[Int64]) -> Int64 {
  counter.val = counter.val + 6500L
  counter.val
}

///|
struct DemoMessageMeta {
  id : String
  timestamp_ms : Int64
}

///|
fn add_message(
  store : @moonchat.ChatStore,
  id_counter : Ref[Int],
  ts_counter : Ref[Int64],
  prefix : String,
  sender : @moonchat.User,
  content : @moonchat.MessageContent,
  status? : @moonchat.MessageStatus = @moonchat.MessageStatus::Sending,
) -> DemoMessageMeta {
  let id = next_message_id(id_counter, prefix)
  let timestamp = next_timestamp(ts_counter)
  let msg = @moonchat.new_message(id, sender, content, timestamp, status~)
  store.add_message(msg)
  { id, timestamp_ms: timestamp }
}

///|
fn reviewed_public_reply(body : String) -> String {
  "Thanks for the details. " + body + " We'll share the next update soon."
}

///|
fn schedule_outbound_status(
  store : @moonchat.ChatStore,
  win : @js_dom.Window,
  id : String,
) -> Unit {
  let _ = win.setTimeout(
    fn() {
      store.update_message_status(id, @moonchat.MessageStatus::Sent) |> ignore
    },
    250,
  )
  let _ = win.setTimeout(
    fn() {
      store.update_message_status(id, @moonchat.MessageStatus::Delivered)
      |> ignore
    },
    900,
  )

}

///|
fn escape_json_string(s : String) -> String {
  let sb = StringBuilder::new(size_hint=s.length())
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn log_payload(kind : String, text : String) -> String {
  "{\"kind\":\"\{kind}\",\"text\":\"\{escape_json_string(text)}\"}"
}

///|
fn log_payload_publish(
  draft_id : String,
  public_id : String,
  text : String,
) -> String {
  "{\"kind\":\"publish\",\"draft_id\":\"\{draft_id}\",\"public_id\":\"\{public_id}\",\"text\":\"\{escape_json_string(text)}\"}"
}

///|
fn format_log_entry(entry : @shared.LogEntry) -> String {
  let actor = if entry.actor_id == "" { "system" } else { entry.actor_id }
  let ticket = if entry.ticket_id == "" { "-" } else { entry.ticket_id }
  "\{entry.created_at} | \{entry.event_type} | \{ticket} | \{entry.entity_id} | \{actor}"
}

///|
fn log_panel_text(entries : Array[@shared.LogEntry]) -> String {
  if entries.is_empty() {
    return "No logs yet."
  }
  entries.map(format_log_entry).join("\n")
}

///|
fn set_log_panel_text(text : String) -> Unit {
  let doc = @js_dom.document()
  match doc.getElementById("log-list") {
    Some(node) => node.setTextContent(text)
    None => ()
  }
}

///|
fn update_log_panel(entries : Array[@shared.LogEntry]) -> Unit {
  set_log_panel_text(log_panel_text(entries))
}

///|
fn build_demo_state(self_id : String) -> @ui.AppViewState {
  let image_url = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='320' height='180'><rect width='100%' height='100%' fill='%23f97316'/><text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='white' font-size='18' font-family='sans-serif'>Airlock</text></svg>"
  let image_attachment : @ui.AttachmentView = {
    name: "status.png",
    url: image_url,
    attachment_type: "image",
    thumbnail_url: image_url,
  }
  let timeline_messages : Array[@ui.TimelineMessage] = [
    {
      message_id: "msg-1",
      text: "Payment failed on checkout.",
      sender_name: "Customer",
      timestamp: "1710000000000",
      is_from_user: true,
      attachments: [],
      reply_thread_id: "",
    },
    {
      message_id: "msg-2",
      text: "Thanks, let me check the logs.",
      sender_name: self_id,
      timestamp: "1710000005000",
      is_from_user: false,
      attachments: [],
      reply_thread_id: "",
    },
    {
      message_id: "msg-3",
      text: "",
      sender_name: "Customer",
      timestamp: "1710000010000",
      is_from_user: true,
      attachments: [image_attachment],
      reply_thread_id: "",
    },
  ]
  let workspace_items : Array[@ui.WorkspaceItem] = [
    {
      message_id: "draft-1",
      text: "Draft reply: We are investigating and will follow up.",
      sender_name: self_id,
      timestamp: "1710000015000",
      is_draft: true,
      draft_status: "checking",
      ai_warnings: ["Tone feels abrupt"],
      ai_suggestions: ["Add greeting", "Offer timeline"],
      can_publish: false,
      can_edit: true,
    },
    {
      message_id: "note-1",
      text: "Internal note: check billing logs for user.",
      sender_name: self_id,
      timestamp: "1710000018000",
      is_draft: false,
      draft_status: "published",
      ai_warnings: [],
      ai_suggestions: [],
      can_publish: false,
      can_edit: false,
    },
  ]
  let mut state = @ui.AppViewState::initial()
  state = @ui.handle_set_connection_status(state, true)
  state = @ui.handle_set_editor_mode(state, @ui.EditorMode::Draft)
  state = @ui.update_timeline_messages(
    state, timeline_messages, "Ticket #A-1042",
  )
  state = @ui.update_workspace_items(state, workspace_items)
  state
}

///|
fn demo_header(title : String, subtitle : String) -> @element.DomNode {
  div(class="airlock-demo__header", [
    h2(class="airlock-demo__title", [text(title)]),
    p(class="airlock-demo__subtitle", [text(subtitle)]),
  ])
}

///|
fn build_demo_view(
  timeline_store : @moonchat.ChatStore,
  workspace_store : @moonchat.ChatStore,
  state : @ui.AppViewState,
  on_send : (String) -> Unit,
  on_simulate : () -> Unit,
  on_publish : () -> Unit,
  on_refresh_logs : () -> Unit,
  self_id : String,
) -> @element.DomNode {
  div(class="airlock-demo", [
    div(class="airlock-demo__pane", [
      demo_header("Timeline", "Chat A / public"),
      div(class="airlock-demo__chat", [
        @moonchat_ui.timeline_view_from_state(
          timeline_store,
          state,
          Some(self_id),
        ),
        div(class="airlock-demo__controls", [
          button(
            class="btn-secondary",
            on=events().click(fn(_) { on_simulate() }),
            [text("Simulate public message")],
          ),
        ]),
      ]),
    ]),
    div(class="airlock-demo__pane", [
      demo_header("Workspace", "Chat B / drafts"),
      div(class="airlock-demo__chat", [
        @moonchat_ui.workspace_view_from_state(
          workspace_store,
          state,
          on_send,
          Some(self_id),
        ),
        div(class="airlock-demo__controls", [
          button(
            class="btn-primary",
            on=events().click(fn(_) { on_publish() }),
            [text("Publish reviewed reply")],
          ),
        ]),
      ]),
    ]),
    div(class="airlock-demo__pane", [
      demo_header("Audit log", "DuckDB / persisted"),
      div(class="airlock-demo__chat", [
        div(class="airlock-demo__log", [
          div(id="log-list", class="airlock-demo__log-content", [
            text("Connecting to log store..."),
          ]),
        ]),
        div(class="airlock-demo__controls", [
          button(
            class="btn-secondary",
            on=events().click(fn(_) { on_refresh_logs() }),
            [text("Refresh logs")],
          ),
        ]),
      ]),
    ]),
  ])
}

///|
fn main {
  let self_id = "Agent Ryo"
  let customer_id = "Customer"
  let demo_ticket_id = "A-1042"
  let state = build_demo_state(self_id)
  let (timeline_store, workspace_store) = @moonchat_ui.new_stores_from_view_state(
    state,
  )
  let self_user = @moonchat.User::{
    id: self_id,
    name: self_id,
    avatar_url: None,
  }
  let customer_user = @moonchat.User::{
    id: customer_id,
    name: customer_id,
    avatar_url: None,
  }
  let id_counter : Ref[Int] = { val: 100 }
  let ts_counter : Ref[Int64] = { val: 1710000020000L }
  let sim_index : Ref[Int] = { val: 0 }
  let log_counter : Ref[Int] = { val: 400 }
  let latest_draft : Ref[String?] = { val: None }
  let latest_draft_id : Ref[String?] = { val: None }
  let log_store_ref : Ref[@logs.LogStore?] = { val: None }
  let pending_logs : Ref[Array[@shared.LogEntry]] = { val: [] }
  let win = @js_dom.window()
  fn refresh_logs() -> Unit {
    match log_store_ref.val {
      Some(store) =>
        store.list_recent(
          on_done=fn(result) {
            match result {
              Ok(entries) => update_log_panel(entries)
              Err(err) => set_log_panel_text("Log query failed: " + "\{err}")
            }
          },
          limit=40,
        )
      None => ()
    }
  }

  fn append_log_entry(entry : @shared.LogEntry) -> Unit {
    match log_store_ref.val {
      Some(store) =>
        store.append_entry(entry, on_complete=fn(result) {
          match result {
            Ok(_) => refresh_logs()
            Err(err) => set_log_panel_text("Log write failed: " + "\{err}")
          }
        })
      None => pending_logs.val.push(entry)
    }
  }

  fn flush_pending_logs() -> Unit {
    match log_store_ref.val {
      Some(store) => {
        for entry in pending_logs.val {
          store.append_entry(entry)
        }
        pending_logs.val = []
        refresh_logs()
      }
      None => ()
    }
  }

  fn open_log_store() -> Unit {
    @logs.LogStore::open(
      on_ready=fn(result) {
        match result {
          Ok(store) => {
            log_store_ref.val = Some(store)
            flush_pending_logs()
          }
          Err(err) => set_log_panel_text("Log store error: " + "\{err}")
        }
      },
      path="airlock_demo_logs.duckdb",
    )
  }

  fn handle_send(body : String) -> Unit {
    if body == "" {
      return
    }
    latest_draft.val = Some(body)
    let meta = add_message(
      workspace_store,
      id_counter,
      ts_counter,
      "draft",
      self_user,
      @moonchat.MessageContent::Text(body),
      status=@moonchat.MessageStatus::Sending,
    )
    latest_draft_id.val = Some(meta.id)
    schedule_outbound_status(workspace_store, win, meta.id)
    let entry = @shared.LogEntry::new(
      next_message_id(log_counter, "log"),
      demo_ticket_id,
      "draft_submitted",
      "draft",
      meta.id,
      self_id,
      log_payload("draft", body),
      meta.timestamp_ms.to_string(),
    )
    append_log_entry(entry)
  }

  let simulated_messages : Array[String] = [
    "Could you share the ETA?", "The issue seems intermittent.", "Thanks! We are standing by.",
  ]
  fn handle_simulate() -> Unit {
    let idx = sim_index.val % simulated_messages.length()
    sim_index.val = sim_index.val + 1
    let body = simulated_messages[idx]
    let meta = add_message(
      timeline_store,
      id_counter,
      ts_counter,
      "pub",
      customer_user,
      @moonchat.MessageContent::Text(body),
      status=@moonchat.MessageStatus::Delivered,
    )
    let entry = @shared.LogEntry::new(
      next_message_id(log_counter, "log"),
      demo_ticket_id,
      "public_message_simulated",
      "message",
      meta.id,
      customer_id,
      log_payload("public", body),
      meta.timestamp_ms.to_string(),
    )
    append_log_entry(entry)
  }

  fn handle_publish() -> Unit {
    match latest_draft.val {
      Some(draft) => {
        latest_draft.val = None
        let draft_id = match latest_draft_id.val {
          Some(id) => id
          None => ""
        }
        latest_draft_id.val = None
        let reviewed = reviewed_public_reply(draft)
        let meta = add_message(
          timeline_store,
          id_counter,
          ts_counter,
          "pub",
          self_user,
          @moonchat.MessageContent::Text(reviewed),
          status=@moonchat.MessageStatus::Delivered,
        )
        let entity_id = if draft_id == "" { meta.id } else { draft_id }
        let payload = log_payload_publish(draft_id, meta.id, reviewed)
        let entry = @shared.LogEntry::new(
          next_message_id(log_counter, "log"),
          demo_ticket_id,
          "draft_published",
          "draft",
          entity_id,
          self_id,
          payload,
          meta.timestamp_ms.to_string(),
        )
        append_log_entry(entry)
      }
      None => ()
    }
  }

  inject_styles(@ui.generate_stylesheet() + "\n" + demo_styles())
  let root = ensure_root("app")
  let view = build_demo_view(
    timeline_store, workspace_store, state, handle_send, handle_simulate, handle_publish,
    refresh_logs, self_id,
  )
  @element.render(root, view)
  open_log_store()
}
