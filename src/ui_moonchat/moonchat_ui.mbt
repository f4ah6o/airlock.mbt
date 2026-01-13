///|
using @element { div }

///|
fn parse_timestamp_ms(timestamp : String) -> Int64 {
  match try? @strconv.parse_int64(timestamp, base=10) {
    Ok(value) => value
    Err(_) => 0L
  }
}

///|
fn attachment_line(att : @ui.AttachmentView) -> String {
  if att.name == "" { "- " + att.url } else { "- " + att.name + " (" + att.url + ")" }
}

///|
fn attachments_block(attachments : Array[@ui.AttachmentView]) -> String {
  attachments.map(attachment_line).join("\n")
}

///|
fn timeline_content(
  message : @ui.TimelineMessage,
) -> @moonchat.MessageContent {
  let attachments = message.attachments
  if attachments.length() == 1 && message.text == "" {
    let att = attachments[0]
    if att.attachment_type == "image" {
      let caption = if att.name == "" { None } else { Some(att.name) }
      return @moonchat.MessageContent::Image(url=att.url, caption=caption)
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
fn timeline_status(
  message : @ui.TimelineMessage,
) -> @moonchat.MessageStatus {
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
    status= status,
  )
}

///|
fn append_section(body : String, title : String, items : Array[String]) -> String {
  if items.is_empty() {
    return body
  }
  let section = title + ":\n" + items.map(fn(item) { "- " + item }).join("\n")
  if body == "" { section } else { body + "\n\n" + section }
}

///|
fn workspace_content(
  item : @ui.WorkspaceItem,
) -> @moonchat.MessageContent {
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
fn workspace_status(
  item : @ui.WorkspaceItem,
) -> @moonchat.MessageStatus {
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
  @moonchat.new_message(
    item.message_id,
    user,
    content,
    timestamp_ms,
    status= status,
  )
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
pub fn set_timeline_messages(
  store : @moonchat.ChatStore,
  messages : Array[@ui.TimelineMessage],
) -> Unit {
  store.set_messages(timeline_messages_to_moonchat(messages))
}

///|
pub fn set_workspace_messages(
  store : @moonchat.ChatStore,
  items : Array[@ui.WorkspaceItem],
) -> Unit {
  store.set_messages(workspace_items_to_moonchat(items))
}

///|
pub fn sync_connection(store : @moonchat.ChatStore, connected : Bool) -> Unit {
  store.set_connected(connected)
}

///|
pub fn timeline_view(
  store : @moonchat.ChatStore,
  self_id? : String,
) -> @moonchat.DomNode {
  div(class="airlock-moonchat airlock-moonchat--timeline", [
    @moonchat.message_list(store, self_id?),
  ])
}

///|
pub fn workspace_view(
  store : @moonchat.ChatStore,
  on_send : (String) -> Unit,
  self_id? : String,
  placeholder? : String = "Write an internal note...",
  disabled? : Bool = false,
) -> @moonchat.DomNode {
  div(class="airlock-moonchat airlock-moonchat--workspace", [
    @moonchat.message_list(store, self_id?),
    @moonchat.input_area(on_send, placeholder~, disabled~),
  ])
}
