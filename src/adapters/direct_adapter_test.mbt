///|
test "direct_message_to_normalized uses room_id and sets flags" {
  let config = AdapterConfig::new("direct", "bot-1", "token")
  let message : @direct_types.ReceivedMessage = {
    id: "msg-1",
    talk_id: "talk-1",
    room_id: "room-1",
    user_id: "user-1",
    domain_id: "domain-1",
    text: "hello",
    msg_type: @direct_types.MsgTypeText,
    content: @direct_types.JsonString("hello"),
    created: 123L,
    raw: None,
  }
  let normalized = direct_message_to_normalized(config, message)
  assert_eq(normalized.channel_id, "room-1")
  assert_eq(normalized.sender_id, "user-1")
  assert_eq(normalized.platform, "direct")
  assert_true(normalized.is_bot |> not)
}

///|
test "direct_message_to_normalized falls back to talk_id" {
  let config = AdapterConfig::new("direct", "bot-1", "token")
  let message : @direct_types.ReceivedMessage = {
    id: "msg-2",
    talk_id: "talk-2",
    room_id: "",
    user_id: "bot-1",
    domain_id: "domain-1",
    text: "ping",
    msg_type: @direct_types.MsgTypeText,
    content: @direct_types.JsonString("ping"),
    created: 456L,
    raw: None,
  }
  let normalized = direct_message_to_normalized(config, message)
  assert_eq(normalized.channel_id, "talk-2")
  assert_true(normalized.is_bot)
}

///|
test "direct_message_to_normalized renders stamp content" {
  let config = AdapterConfig::new("direct", "bot-1", "token")
  let content = @direct_types.JsonObject(
    Map::from_array([
      ("stamp_set", @direct_types.JsonString("main")),
      ("stamp_index", @direct_types.JsonString("3")),
    ]),
  )
  let message : @direct_types.ReceivedMessage = {
    id: "msg-3",
    talk_id: "talk-3",
    room_id: "room-3",
    user_id: "user-3",
    domain_id: "domain-1",
    text: "",
    msg_type: @direct_types.MsgTypeStamp,
    content,
    created: 789L,
    raw: None,
  }
  let normalized = direct_message_to_normalized(config, message)
  assert_eq(normalized.text, "[stamp] main:3")
}

///|
test "direct_message_to_normalized renders select reply content" {
  let config = AdapterConfig::new("direct", "bot-1", "token")
  let content = @direct_types.JsonObject(
    Map::from_array([
      ("question", @direct_types.JsonString("Pick one")),
      (
        "options",
        @direct_types.JsonArray([
          @direct_types.JsonString("A"),
          @direct_types.JsonString("B"),
        ]),
      ),
      ("response", @direct_types.JsonNumber(1.0)),
    ]),
  )
  let message : @direct_types.ReceivedMessage = {
    id: "msg-4",
    talk_id: "talk-4",
    room_id: "room-4",
    user_id: "user-4",
    domain_id: "domain-1",
    text: "",
    msg_type: @direct_types.MsgTypeSelectReply,
    content,
    created: 790L,
    raw: None,
  }
  let normalized = direct_message_to_normalized(config, message)
  assert_eq(normalized.text, "[select-reply] Pick one -> B (index=1)")
}

///|
test "direct_message_to_normalized extracts file attachment" {
  let config = AdapterConfig::new("direct", "bot-1", "token")
  let content = @direct_types.JsonObject(
    Map::from_array([
      ("file_id", @direct_types.JsonString("f-1")),
      ("name", @direct_types.JsonString("manual.pdf")),
      ("content_type", @direct_types.JsonString("application/pdf")),
      ("url", @direct_types.JsonString("https://direct/files/f-1")),
    ]),
  )
  let message : @direct_types.ReceivedMessage = {
    id: "msg-5",
    talk_id: "talk-5",
    room_id: "room-5",
    user_id: "user-5",
    domain_id: "domain-1",
    text: "",
    msg_type: @direct_types.MsgTypeFile,
    content,
    created: 791L,
    raw: None,
  }
  let normalized = direct_message_to_normalized(config, message)
  assert_eq(normalized.attachments.length(), 1)
  assert_eq(normalized.attachments[0].name, "manual.pdf")
  assert_eq(normalized.attachments[0].url, "https://direct/files/f-1")
  assert_eq(normalized.text, "[file] manual.pdf")
}

///|
test "direct_message_to_normalized prefers message attachment_url" {
  let config = AdapterConfig::new("direct", "bot-1", "token")
  let content = @direct_types.JsonObject(
    Map::from_array([
      ("file_id", @direct_types.JsonString("f-2")),
      ("attachment_name", @direct_types.JsonString("from-attachment-url.pdf")),
      ("attachment_url", @direct_types.JsonString("https://direct/files/f-2")),
      ("attachment_content_type", @direct_types.JsonString("application/pdf")),
    ]),
  )
  let message : @direct_types.ReceivedMessage = {
    id: "msg-6",
    talk_id: "talk-6",
    room_id: "room-6",
    user_id: "user-6",
    domain_id: "domain-1",
    text: "",
    msg_type: @direct_types.MsgTypeFile,
    content,
    created: 792L,
    raw: None,
  }
  let normalized = direct_message_to_normalized(config, message)
  assert_eq(normalized.attachments.length(), 1)
  assert_eq(normalized.attachments[0].name, "from-attachment-url.pdf")
  assert_eq(normalized.attachments[0].url, "https://direct/files/f-2")
}

///|
test "normalized message converts to inbound message" {
  let normalized = NormalizedMessage::new(
    "ext-1", "direct4b", "room-1", "user-1", "alice", "hello", "2026-02-16T00:00:00Z",
  )
  let inbound = normalized.to_inbound()
  assert_eq(inbound.external_id, "ext-1")
  assert_eq(inbound.channel_id, "room-1")
  assert_eq(inbound.text, "hello")
}
