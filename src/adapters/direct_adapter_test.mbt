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
