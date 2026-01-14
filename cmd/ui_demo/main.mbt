///|
using @element {button, div, events, h2, p, text}

///|
fn demo_styles() -> String {
  let lines : Array[String] = [
    "html, body {", "  margin: 0;", "  padding: 0;", "  height: 100%;", "  font-family: \"Space Grotesk\", \"Noto Sans JP\", \"Segoe UI\", sans-serif;",
    "}", "#app {", "  height: 100%;", "}", ".airlock-demo {", "  display: grid;",
    "  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);", "  gap: 18px;", "  height: 100%;",
    "  padding: 20px;", "  box-sizing: border-box;", "  background: radial-gradient(circle at top, #ffffff 0%, #fdf4e7 45%, #f8f9fb 100%);",
    "}", ".airlock-demo__pane {", "  display: flex;", "  flex-direction: column;",
    "  min-height: 0;", "}", ".airlock-demo__header {", "  display: flex;", "  flex-direction: column;",
    "  gap: 4px;", "  margin-bottom: 12px;", "}", ".airlock-demo__title {", "  margin: 0;",
    "  font-size: 18px;", "  letter-spacing: 0.02em;", "}", ".airlock-demo__subtitle {",
    "  margin: 0;", "  color: #6b7280;", "  font-size: 13px;", "}", ".airlock-demo__chat {",
    "  flex: 1;", "  min-height: 0;", "  display: flex;", "  flex-direction: column;",
    "  gap: 12px;", "}", ".airlock-demo__controls {", "  display: flex;", "  justify-content: flex-end;",
    "  gap: 8px;", "}", ".airlock-demo__chat .airlock-moonchat {", "  flex: 1;",
    "  height: auto;", "}", "@media (max-width: 900px) {", "  .airlock-demo {", "    grid-template-columns: 1fr;",
    "  }", "}",
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
fn add_message(
  store : @moonchat.ChatStore,
  id_counter : Ref[Int],
  ts_counter : Ref[Int64],
  prefix : String,
  sender : @moonchat.User,
  content : @moonchat.MessageContent,
  status? : @moonchat.MessageStatus = @moonchat.MessageStatus::Sending,
) -> String {
  let id = next_message_id(id_counter, prefix)
  let timestamp = next_timestamp(ts_counter)
  let msg = @moonchat.new_message(id, sender, content, timestamp, status~)
  store.add_message(msg)
  id
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
  self_id : String,
) -> @element.DomNode {
  div(class="airlock-demo", [
    div(class="airlock-demo__pane", [
      demo_header("Timeline", "Chat A / public"),
      div(class="airlock-demo__chat", [
        @moonchat_ui.timeline_view_from_state(timeline_store, state, self_id~),
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
          self_id~,
        ),
      ]),
    ]),
  ])
}

///|
fn main {
  let self_id = "Agent Ryo"
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
    id: "Customer",
    name: "Customer",
    avatar_url: None,
  }
  let id_counter : Ref[Int] = { val: 100 }
  let ts_counter : Ref[Int64] = { val: 1710000020000L }
  let sim_index : Ref[Int] = { val: 0 }
  let win = @js_dom.window()
  fn handle_send(body : String) -> Unit {
    if body == "" {
      return
    }
    let id = add_message(
      workspace_store,
      id_counter,
      ts_counter,
      "draft",
      self_user,
      @moonchat.MessageContent::Text(body),
      status=@moonchat.MessageStatus::Sending,
    )
    schedule_outbound_status(workspace_store, win, id)
    let _ = add_message(
      timeline_store,
      id_counter,
      ts_counter,
      "pub",
      self_user,
      @moonchat.MessageContent::Text(body),
      status=@moonchat.MessageStatus::Delivered,
    )

  }

  let simulated_messages : Array[String] = [
    "Could you share the ETA?", "The issue seems intermittent.", "Thanks! We are standing by.",
  ]
  fn handle_simulate() -> Unit {
    let idx = sim_index.val % simulated_messages.length()
    sim_index.val = sim_index.val + 1
    let body = simulated_messages[idx]
    let _ = add_message(
      timeline_store,
      id_counter,
      ts_counter,
      "pub",
      customer_user,
      @moonchat.MessageContent::Text(body),
      status=@moonchat.MessageStatus::Delivered,
    )

  }

  inject_styles(@ui.generate_stylesheet() + "\n" + demo_styles())
  let root = ensure_root("app")
  let view = build_demo_view(
    timeline_store, workspace_store, state, handle_send, handle_simulate, self_id,
  )
  @element.render(root, view)
}
