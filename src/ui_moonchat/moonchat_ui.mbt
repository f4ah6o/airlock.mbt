///|
using @element {button, div, input, text}

///|
fn parse_timestamp_ms(timestamp : String) -> Int64 {
  try @strconv.parse_int64(timestamp, base=10) catch {
    _ => 0L
  } noraise {
    value => value
  }
}

///|
fn attachment_line(att : @ui.AttachmentView) -> String {
  if att.name == "" {
    "- " + att.url
  } else {
    "- " + att.name + " (" + att.url + ")"
  }
}

///|
fn attachments_block(attachments : Array[@ui.AttachmentView]) -> String {
  attachments.map(attachment_line).join("\n")
}

///|
fn timeline_content(message : @ui.TimelineMessage) -> @moonchat.MessageContent {
  let attachments = message.attachments
  if attachments.length() == 1 && message.text == "" {
    let att = attachments[0]
    if att.attachment_type == "image" {
      let caption = if att.name == "" { None } else { Some(att.name) }
      return @moonchat.MessageContent::Image(url=att.url, caption~)
    }
  }
  if attachments.length() > 0 {
    let list = attachments_block(attachments)
    let body = if message.text == "" {
      "Attachments:\n" + list
    } else {
      message.text + "\n\nAttachments:\n" + list
    }
    return @moonchat.MessageContent::Markdown(body)
  }
  @moonchat.MessageContent::Text(message.text)
}

///|
fn timeline_status(message : @ui.TimelineMessage) -> @moonchat.MessageStatus {
  if message.is_from_user {
    @moonchat.MessageStatus::Delivered
  } else {
    @moonchat.MessageStatus::Sent
  }
}

///|
fn user_from_name(name : String) -> @moonchat.User {
  let display = if name == "" { "unknown" } else { name }
  { id: display, name: display, avatar_url: None }
}

///|
pub fn timeline_message_to_moonchat(
  message : @ui.TimelineMessage,
) -> @moonchat.Message {
  let user = user_from_name(message.sender_name)
  let content = timeline_content(message)
  let timestamp_ms = parse_timestamp_ms(message.timestamp)
  let status = timeline_status(message)
  @moonchat.new_message(
    message.message_id,
    user,
    content,
    timestamp_ms,
    status~,
  )
}

///|
fn append_section(
  body : String,
  title : String,
  items : Array[String],
) -> String {
  if items.is_empty() {
    return body
  }
  let section = title + ":\n" + items.map(fn(item) { "- " + item }).join("\n")
  if body == "" {
    section
  } else {
    body + "\n\n" + section
  }
}

///|
fn workspace_content(item : @ui.WorkspaceItem) -> @moonchat.MessageContent {
  let mut body = item.text
  body = append_section(body, "Warnings", item.ai_warnings)
  body = append_section(body, "Suggestions", item.ai_suggestions)
  if item.ai_warnings.length() > 0 || item.ai_suggestions.length() > 0 {
    @moonchat.MessageContent::Markdown(body)
  } else {
    @moonchat.MessageContent::Text(body)
  }
}

///|
fn workspace_status(item : @ui.WorkspaceItem) -> @moonchat.MessageStatus {
  match item.draft_status {
    "published" => @moonchat.MessageStatus::Read
    "checked" => @moonchat.MessageStatus::Delivered
    "rejected" => @moonchat.MessageStatus::Failed
    "checking" => @moonchat.MessageStatus::Sending
    "pending" => @moonchat.MessageStatus::Sending
    _ => @moonchat.MessageStatus::Sent
  }
}

///|
pub fn workspace_item_to_moonchat(
  item : @ui.WorkspaceItem,
) -> @moonchat.Message {
  let user = user_from_name(item.sender_name)
  let content = workspace_content(item)
  let timestamp_ms = parse_timestamp_ms(item.timestamp)
  let status = workspace_status(item)
  @moonchat.new_message(item.message_id, user, content, timestamp_ms, status~)
}

///|
fn timeline_messages_to_moonchat(
  messages : Array[@ui.TimelineMessage],
) -> Array[@moonchat.Message] {
  messages.map(timeline_message_to_moonchat)
}

///|
fn workspace_items_to_moonchat(
  items : Array[@ui.WorkspaceItem],
) -> Array[@moonchat.Message] {
  items.map(workspace_item_to_moonchat)
}

///|
pub fn set_timeline_messages(
  store : @moonchat.ChatStore,
  messages : Array[@ui.TimelineMessage],
) -> Unit {
  let moonchat_messages = timeline_messages_to_moonchat(messages)
  for msg in moonchat_messages {
    store.add_message(msg)
  }
}

///|
pub fn set_workspace_messages(
  store : @moonchat.ChatStore,
  items : Array[@ui.WorkspaceItem],
) -> Unit {
  let moonchat_messages = workspace_items_to_moonchat(items)
  for msg in moonchat_messages {
    store.add_message(msg)
  }
}

///|
pub fn new_timeline_store(
  messages : Array[@ui.TimelineMessage],
) -> @moonchat.ChatStore {
  let store = @moonchat.new_store()
  set_timeline_messages(store, messages)
  store
}

///|
pub fn new_workspace_store(
  items : Array[@ui.WorkspaceItem],
) -> @moonchat.ChatStore {
  let store = @moonchat.new_store()
  set_workspace_messages(store, items)
  store
}

///|
pub fn sync_connection(store : @moonchat.ChatStore, connected : Bool) -> Unit {
  store.set_connected(connected)
}

///|
fn workspace_placeholder(state : @ui.AppViewState) -> String {
  match state.workspace.editor_mode {
    @ui.EditorMode::Note => "Write an internal note..."
    @ui.EditorMode::Draft => "Write a draft response..."
  }
}

///|
pub fn new_stores_from_view_state(
  state : @ui.AppViewState,
) -> (@moonchat.ChatStore, @moonchat.ChatStore) {
  let timeline_store = new_timeline_store(state.timeline.messages)
  let workspace_store = new_workspace_store(state.workspace.items)
  sync_connection(timeline_store, state.is_connected)
  sync_connection(workspace_store, state.is_connected)
  (timeline_store, workspace_store)
}

///|
pub fn sync_from_view_state(
  timeline_store : @moonchat.ChatStore,
  workspace_store : @moonchat.ChatStore,
  state : @ui.AppViewState,
) -> Unit {
  set_timeline_messages(timeline_store, state.timeline.messages)
  set_workspace_messages(workspace_store, state.workspace.items)
  sync_connection(timeline_store, state.is_connected)
  sync_connection(workspace_store, state.is_connected)
}

///|
fn format_message_content(content : @moonchat.MessageContent) -> String {
  match content {
    @moonchat.MessageContent::Text(t) => t
    @moonchat.MessageContent::Markdown(m) => m
    @moonchat.MessageContent::Image(url~, caption~) => {
      let caption_text = match caption {
        Some(c) => " (" + c + ")"
        None => ""
      }
      "[Image: " + url + caption_text + "]"
    }
    @moonchat.MessageContent::System(s) => "[System: " + s + "]"
  }
}

///|
fn message_list(
  store : @moonchat.ChatStore,
  self_id : String?,
) -> @element.DomNode {
  let messages = store.get_messages()
  let message_divs = messages.map(fn(msg) {
    let is_self = match self_id {
      Some(id) => msg.sender.id == id
      None => false
    }
    let sender_name = if is_self { "You" } else { msg.sender.name }
    let content_text = format_message_content(msg.content)
    div(
      class="airlock-message" +
        (if is_self { " airlock-message--self" } else { " airlock-message--other" }),
      [text(sender_name + ": " + content_text)],
    )
  })
  div(class="airlock-messages", message_divs)
}

///|
fn input_area(
  on_send : (String) -> Unit,
  placeholder? : String,
  disabled? : Bool,
) -> @element.DomNode {
  let placeholder_text = match placeholder {
    Some(p) => p
    None => ""
  }

  let disabled_value = match disabled {
    Some(d) => d
    None => false
  }

  div(class="airlock-input-area", [
    input(
      type_="text",
      class="airlock-input-field",
      placeholder=placeholder_text,
      disabled=disabled_value,
      on=@element.events()
        .keydown(fn(e : @js_dom.KeyboardEvent) {
          if e.key == "Enter" {
            let target_element = e.target()
            let input = @js_dom.HTMLInputElement::cast_from_element(target_element)
            if input.value != "" {
              on_send(input.value)
              input.value = ""
            }
          }
        })
    ),
    button(
      class="airlock-input-button",
      disabled=disabled_value,
      on=@element.events().click(fn(_) {
        // Get input value via DOM
        let doc = @js_dom.document()
        match doc.querySelector(".airlock-input-field") {
          Some(input_elem) => {
            let input = @js_dom.HTMLInputElement::cast_from_element(input_elem)
            if input.value != "" {
              on_send(input.value)
              input.value = ""
            }
          }
          None => ()
        }
        }),
      [text("Send")],
    ),
  ])
}

///|
pub fn timeline_view_from_state(
  store : @moonchat.ChatStore,
  state : @ui.AppViewState,
  self_id : String?,
) -> @element.DomNode {
  set_timeline_messages(store, state.timeline.messages)
  sync_connection(store, state.is_connected)
  timeline_view(store, self_id)
}

///|
pub fn workspace_view_from_state(
  store : @moonchat.ChatStore,
  state : @ui.AppViewState,
  on_send : (String) -> Unit,
  self_id : String?,
) -> @element.DomNode {
  set_workspace_messages(store, state.workspace.items)
  sync_connection(store, state.is_connected)
  let placeholder = workspace_placeholder(state)
  let disabled = state.workspace.is_submitting
  workspace_view(store, on_send, self_id, placeholder~, disabled~)
}

///|
pub fn timeline_view(
  store : @moonchat.ChatStore,
  self_id : String?,
) -> @element.DomNode {
  div(class="airlock-moonchat airlock-moonchat--timeline", [
    message_list(store, self_id),
  ])
}

///|
pub fn workspace_view(
  store : @moonchat.ChatStore,
  on_send : (String) -> Unit,
  self_id : String?,
  placeholder? : String = "Write an internal note...",
  disabled? : Bool = false,
) -> @element.DomNode {
  div(class="airlock-moonchat airlock-moonchat--workspace", [
    message_list(store, self_id),
    input_area(on_send, placeholder~, disabled~),
  ])
}
