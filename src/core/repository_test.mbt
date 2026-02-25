///|
test "TicketRepository create and get" {
  let repo = TicketRepository::new()
  let chat_a = @shared.ChatAMetadata::new("slack", "C12345", "ts_001")
  let ticket = @shared.Ticket::new("tkt_001", "Test Issue", chat_a)

  // Create
  let create_result = repo.create(ticket)
  assert_true(create_result is Ok(_))

  // Get
  let get_result = repo.get("tkt_001")
  match get_result {
    Ok(t) => {
      assert_eq(t.ticket_id, "tkt_001")
      assert_eq(t.subject, "Test Issue")
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TicketRepository duplicate create fails" {
  let repo = TicketRepository::new()
  let chat_a = @shared.ChatAMetadata::new("slack", "C12345", "ts_001")
  let ticket = @shared.Ticket::new("tkt_001", "Test Issue", chat_a)
  let _ = repo.create(ticket)
  let result = repo.create(ticket)
  match result {
    Ok(_) => assert_true(false)
    Err(e) =>
      match e {
        DuplicateKey(_) => assert_true(true)
        _ => assert_true(false)
      }
  }
}

///|
test "TicketRepository update with optimistic locking" {
  let repo = TicketRepository::new()
  let chat_a = @shared.ChatAMetadata::new("slack", "C12345", "ts_001")
  let ticket = @shared.Ticket::new("tkt_001", "Test Issue", chat_a)
  let _ = repo.create(ticket)

  // Update with correct version
  let updated = @shared.Ticket::{ ..ticket, subject: "Updated Issue" }
  let result = repo.update(updated)
  assert_true(result is Ok(_))

  // Verify update
  let get_result = repo.get("tkt_001")
  match get_result {
    Ok(t) => {
      assert_eq(t.subject, "Updated Issue")
      assert_eq(t.lock_version, 2) // Version incremented
    }
    Err(_) => assert_true(false)
  }
}

///|
test "TicketRepository update concurrency conflict" {
  let repo = TicketRepository::new()
  let chat_a = @shared.ChatAMetadata::new("slack", "C12345", "ts_001")
  let ticket = @shared.Ticket::new("tkt_001", "Test Issue", chat_a)
  let _ = repo.create(ticket)

  // First update succeeds
  let updated1 = @shared.Ticket::{ ..ticket, subject: "Update 1" }
  let _ = repo.update(updated1)

  // Second update with stale version fails
  let updated2 = @shared.Ticket::{ ..ticket, subject: "Update 2" }
  let result = repo.update(updated2)
  match result {
    Ok(_) => assert_true(false)
    Err(e) =>
      match e {
        ConcurrencyConflict(_) => assert_true(true)
        _ => assert_true(false)
      }
  }
}

///|
test "TicketRepository list by status" {
  let repo = TicketRepository::new()
  let chat_a1 = @shared.ChatAMetadata::new("slack", "C12345", "ts_001")
  let chat_a2 = @shared.ChatAMetadata::new("slack", "C12346", "ts_002")
  let ticket1 = @shared.Ticket::new("tkt_001", "Open Issue", chat_a1)
  let ticket2 = @shared.Ticket::{
    ..@shared.Ticket::new("tkt_002", "Closed Issue", chat_a2),
    status: @shared.TicketStatus::Closed,
  }
  let _ = repo.create(ticket1)
  let _ = repo.create(ticket2)
  let open_tickets = repo.list_by_status(@shared.TicketStatus::Open)
  assert_eq(open_tickets.length(), 1)
  assert_eq(open_tickets[0].ticket_id, "tkt_001")
  let closed_tickets = repo.list_by_status(@shared.TicketStatus::Closed)
  assert_eq(closed_tickets.length(), 1)
  assert_eq(closed_tickets[0].ticket_id, "tkt_002")
}

///|
test "MessageRepository create and get" {
  let repo = MessageRepository::new()
  let msg = @shared.Message::new(
    "msg_001",
    "tkt_001",
    "Hello",
    @shared.Visibility::Public,
    @shared.Origin::ChatA,
    "user_001",
  )
  let create_result = repo.create(msg)
  assert_true(create_result is Ok(_))
  let get_result = repo.get("msg_001")
  match get_result {
    Ok(m) => {
      assert_eq(m.message_id, "msg_001")
      assert_eq(m.text, "Hello")
    }
    Err(_) => assert_true(false)
  }
}

///|
test "MessageRepository idempotency key check" {
  let repo = MessageRepository::new()
  let msg1 = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Draft 1", "admin_001", "key_001",
    )
  }
  let msg2 = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_002", "tkt_001", "Draft 2", "admin_001", "key_001",
    )
  }
  let _ = repo.create(msg1)
  let result = repo.create(msg2)
  match result {
    Ok(_) => assert_true(false)
    Err(e) =>
      match e {
        DuplicateKey(_) => assert_true(true)
        _ => assert_true(false)
      }
  }
}

///|
test "MessageRepository list by ticket" {
  let repo = MessageRepository::new()
  let msg1 = @shared.Message::new(
    "msg_001",
    "tkt_001",
    "Message 1",
    @shared.Visibility::Public,
    @shared.Origin::ChatA,
    "user_001",
  )
  let msg2 = @shared.Message::new(
    "msg_002",
    "tkt_001",
    "Message 2",
    @shared.Visibility::Internal,
    @shared.Origin::Console,
    "admin_001",
  )
  let msg3 = @shared.Message::new(
    "msg_003",
    "tkt_002",
    "Message 3",
    @shared.Visibility::Public,
    @shared.Origin::ChatA,
    "user_002",
  )
  let _ = repo.create(msg1)
  let _ = repo.create(msg2)
  let _ = repo.create(msg3)
  let tkt1_messages = repo.list_by_ticket("tkt_001")
  assert_eq(tkt1_messages.length(), 2)
  let tkt2_messages = repo.list_by_ticket("tkt_002")
  assert_eq(tkt2_messages.length(), 1)
}

///|
test "MessageRepository list public only" {
  let repo = MessageRepository::new()
  let msg1 = @shared.Message::new(
    "msg_001",
    "tkt_001",
    "Public",
    @shared.Visibility::Public,
    @shared.Origin::ChatA,
    "user_001",
  )
  let msg2 = @shared.Message::new(
    "msg_002",
    "tkt_001",
    "Internal",
    @shared.Visibility::Internal,
    @shared.Origin::Console,
    "admin_001",
  )
  let _ = repo.create(msg1)
  let _ = repo.create(msg2)
  let public_messages = repo.list_public_by_ticket("tkt_001")
  assert_eq(public_messages.length(), 1)
  assert_eq(public_messages[0].visibility, @shared.Visibility::Public)
}

///|
test "MessageRepository get by idempotency key" {
  let repo = MessageRepository::new()
  let msg = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Draft", "admin_001", "unique_key_123",
    )
  }
  let _ = repo.create(msg)
  let found = repo.get_by_idempotency_key("unique_key_123")
  match found {
    Some(m) => assert_eq(m.message_id, "msg_001")
    None => assert_true(false)
  }
  let not_found = repo.get_by_idempotency_key("nonexistent_key")
  assert_true(not_found is None)
}

///|
test "MessageRepository has idempotency key" {
  let repo = MessageRepository::new()
  let msg = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Draft", "admin_001", "key_123",
    )
  }
  let _ = repo.create(msg)
  assert_true(repo.has_idempotency_key("key_123"))
  assert_false(repo.has_idempotency_key("other_key"))
}

///|
test "TicketRepository list by group" {
  let repo = TicketRepository::new()
  let chat_a = @shared.ChatAMetadata::new("direct4b", "dm_001", "cursor")
  let t1 = @shared.Ticket::new("tkt_001", "Group A", chat_a, group_id="grp-a")
  let t2 = @shared.Ticket::new("tkt_002", "Group B", chat_a, group_id="grp-b")
  let _ = repo.create(t1)
  let _ = repo.create(t2)
  let a_tickets = repo.list_by_group("grp-a")
  assert_eq(a_tickets.length(), 1)
  assert_eq(a_tickets[0].group_id, "grp-a")
}

///|
test "MessageRepository list by group and visibility" {
  let repo = MessageRepository::new()
  let msg1 = @shared.Message::new(
    "msg_001",
    "tkt_001",
    "public a",
    @shared.Visibility::Public,
    @shared.Origin::ChatA,
    "user_001",
    group_id="grp-a",
  )
  let msg2 = @shared.Message::new_note(
    "msg_002",
    "tkt_001",
    "note a",
    "agent",
    group_id="grp-a",
  )
  let msg3 = @shared.Message::new(
    "msg_003",
    "tkt_002",
    "public b",
    @shared.Visibility::Public,
    @shared.Origin::ChatA,
    "user_002",
    group_id="grp-b",
  )
  let _ = repo.create(msg1)
  let _ = repo.create(msg2)
  let _ = repo.create(msg3)
  assert_eq(repo.list_by_group("grp-a").length(), 2)
  assert_eq(repo.list_public_by_group("grp-a").length(), 1)
  assert_eq(repo.list_internal_by_group("grp-a").length(), 1)
}

///|
test "RouteBindingRepository resolve" {
  let repo = RouteBindingRepository::new()
  repo.upsert(
    @shared.RouteBinding::new(
      "direct4b", "bot@example.com", "room-1", "grp-help",
    ),
  )
  let found = repo.resolve("direct4b", "bot@example.com", "room-1")
  match found {
    Some(binding) => assert_eq(binding.group_id, "grp-help")
    None => assert_true(false)
  }
  repo.delete("direct4b", "bot@example.com", "room-1")
  assert_true(repo.resolve("direct4b", "bot@example.com", "room-1") is None)
}

///|
test "GroupMemberRepository permission checks" {
  let repo = GroupMemberRepository::new()
  repo.upsert(
    @shared.GroupMember::new("grp-a", "user-1", roles=[@shared.Viewer]),
  )
  repo.upsert(
    @shared.GroupMember::new("grp-a", "agent-1", roles=[@shared.Agent]),
  )
  assert_true(repo.is_group_member("grp-a", "user-1"))
  assert_false(repo.can_post("grp-a", "user-1"))
  assert_true(repo.can_post("grp-a", "agent-1"))
}
