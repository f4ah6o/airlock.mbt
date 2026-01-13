///|
fn make_attachment(
  name : String,
  url : String,
  attachment_type : String,
) -> @ui.AttachmentView {
  { name, url, attachment_type, thumbnail_url: "" }
}

///|
test "timeline_message_to_moonchat text" {
  let message : @ui.TimelineMessage = {
    message_id: "msg-1",
    text: "Hello",
    sender_name: "Alice",
    timestamp: "168000",
    is_from_user: true,
    attachments: [],
    reply_thread_id: "",
  }
  let converted = timeline_message_to_moonchat(message)
  let snapshot = converted.snapshot()
  assert_eq(snapshot.sender.name, "Alice")
  assert_eq(snapshot.timestamp_ms, 168000L)
  assert_eq(snapshot.content, @moonchat.MessageContent::Text("Hello"))
  assert_eq(snapshot.status, @moonchat.MessageStatus::Delivered)
}

///|
test "timeline_message_to_moonchat image attachment" {
  let image = make_attachment("photo", "https://img", "image")
  let message : @ui.TimelineMessage = {
    message_id: "msg-2",
    text: "",
    sender_name: "Bob",
    timestamp: "10",
    is_from_user: false,
    attachments: [image],
    reply_thread_id: "",
  }
  let snapshot = timeline_message_to_moonchat(message).snapshot()
  assert_eq(
    snapshot.content,
    @moonchat.MessageContent::Image(url="https://img", caption=Some("photo")),
  )
  assert_eq(snapshot.status, @moonchat.MessageStatus::Sent)
}

///|
test "timeline_message_to_moonchat attachments as markdown" {
  let doc = make_attachment("doc.txt", "https://doc", "file")
  let message : @ui.TimelineMessage = {
    message_id: "msg-3",
    text: "See file",
    sender_name: "Cara",
    timestamp: "5",
    is_from_user: false,
    attachments: [doc],
    reply_thread_id: "",
  }
  let snapshot = timeline_message_to_moonchat(message).snapshot()
  let expected = "See file\n\nAttachments:\n- doc.txt (https://doc)"
  assert_eq(snapshot.content, @moonchat.MessageContent::Markdown(expected))
}

///|
test "timeline_message_to_moonchat invalid timestamp" {
  let message : @ui.TimelineMessage = {
    message_id: "msg-4",
    text: "Time?",
    sender_name: "Dana",
    timestamp: "invalid",
    is_from_user: true,
    attachments: [],
    reply_thread_id: "",
  }
  let snapshot = timeline_message_to_moonchat(message).snapshot()
  assert_eq(snapshot.timestamp_ms, 0L)
}

///|
test "workspace_item_to_moonchat markdown and status" {
  let item : @ui.WorkspaceItem = {
    message_id: "w-1",
    text: "Draft reply",
    sender_name: "Agent",
    timestamp: "12",
    is_draft: true,
    draft_status: "published",
    ai_warnings: ["Needs tone"],
    ai_suggestions: ["Add greeting", "Clarify steps"],
    can_publish: true,
    can_edit: true,
  }
  let snapshot = workspace_item_to_moonchat(item).snapshot()
  let expected = "Draft reply\n\nWarnings:\n- Needs tone\n\nSuggestions:\n- Add greeting\n- Clarify steps"
  assert_eq(snapshot.content, @moonchat.MessageContent::Markdown(expected))
  assert_eq(snapshot.status, @moonchat.MessageStatus::Read)
}
