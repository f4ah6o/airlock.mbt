///|
test "TicketStatus to_string" {
  assert_eq(TicketStatus::Open.to_string(), "open")
  assert_eq(TicketStatus::Closed.to_string(), "closed")
  assert_eq(TicketStatus::Pending.to_string(), "pending")
}

///|
test "Visibility to_string" {
  assert_eq(Visibility::Public.to_string(), "public")
  assert_eq(Visibility::Internal.to_string(), "internal")
}

///|
test "DraftStatus to_string" {
  assert_eq(DraftStatus::Pending.to_string(), "pending")
  assert_eq(DraftStatus::Checking.to_string(), "checking")
  assert_eq(DraftStatus::Checked.to_string(), "checked")
  assert_eq(DraftStatus::Rejected.to_string(), "rejected")
  assert_eq(DraftStatus::Published.to_string(), "published")
}

///|
test "Attachment creation" {
  let attachment = Attachment::new(
    AttachmentType::Image,
    "https://example.com/img.png",
    "screenshot.png",
  )
  assert_eq(attachment.attachment_type, AttachmentType::Image)
  assert_eq(attachment.url, "https://example.com/img.png")
  assert_eq(attachment.name, "screenshot.png")
}

///|
test "Ticket creation" {
  let chat_a = ChatAMetadata::new("slack", "C12345", "ts_001")
  let ticket = Ticket::new("tkt_001", "VPN Error", chat_a)
  assert_eq(ticket.ticket_id, "tkt_001")
  assert_eq(ticket.subject, "VPN Error")
  assert_eq(ticket.status, TicketStatus::Open)
  assert_eq(ticket.chat_a.platform, "slack")
  assert_eq(ticket.lock_version, 1)
}

///|
test "Message creation" {
  let msg = Message::new(
    "msg_001",
    "tkt_001",
    "Hello",
    Visibility::Public,
    Origin::ChatA,
    "user_001",
  )
  assert_eq(msg.message_id, "msg_001")
  assert_eq(msg.ticket_id, "tkt_001")
  assert_eq(msg.visibility, Visibility::Public)
  assert_eq(msg.origin, Origin::ChatA)
  assert_eq(msg.is_draft, false)
}

///|
test "Draft message creation" {
  let draft = Message::new_draft(
    "msg_002", "tkt_001", "Draft reply", "admin_001", "uuid_123",
  )
  assert_eq(draft.is_draft, true)
  assert_eq(draft.draft_status, DraftStatus::Pending)
  assert_eq(draft.visibility, Visibility::Internal)
  assert_eq(draft.origin, Origin::Console)
  assert_eq(draft.idempotency_key, "uuid_123")
}

///|
test "Note message creation" {
  let note = Message::new_note(
    "msg_003", "tkt_001", "Internal note", "admin_001",
  )
  assert_eq(note.is_draft, false)
  assert_eq(note.visibility, Visibility::Internal)
  assert_eq(note.origin, Origin::Console)
}

///|
test "User creation" {
  let user = User::new("user_001", "John Doe", "john@example.com")
  assert_eq(user.is_admin, false)
  let admin = User::new_admin("admin_001", "Admin User", "admin@example.com")
  assert_eq(admin.is_admin, true)
}

///|
test "AICheckResult creation" {
  let pass = AICheckResult::pass()
  assert_eq(pass.passed, true)
  assert_eq(pass.warnings.length(), 0)
  let fail = AICheckResult::fail(["Warning 1", "Warning 2"])
  assert_eq(fail.passed, false)
  assert_eq(fail.warnings.length(), 2)
}
