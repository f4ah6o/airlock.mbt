///|
fn test_now() -> String {
  "2026-02-16T00:00:00Z"
}

///|
fn id_gen() -> () -> String {
  let counter : Ref[Int] = { val: 0 }
  fn() {
    counter.val = counter.val + 1
    "id_\{counter.val.to_string()}"
  }
}

///|
test "ingest_incoming creates ticket and message" {
  let ticket_repo = TicketRepository::new()
  let message_repo = MessageRepository::new()
  let ctx = IngestContext::new(ticket_repo, message_repo, id_gen(), test_now)
  let inbound = @shared.InboundMessage::new(
    "ext_001", "direct4b", "room_001", "user_001", "alice", "VPN is down", "2026-02-16T01:00:00Z",
  )
  let result = ingest_incoming(ctx, inbound)
  match result {
    Ok(Created(ticket_id, message_id)) => {
      assert_true(ticket_id != "")
      assert_true(message_id != "")
      let ticket = match ticket_repo.get(ticket_id) {
        Ok(t) => t
        Err(_) => {
          assert_true(false)
          @shared.Ticket::new("", "", @shared.ChatAMetadata::new("", "", ""))
        }
      }
      assert_eq(ticket.chat_a.dm_id, "room_001")
      assert_eq(ticket.chat_a.last_inbound_cursor, "ext_001")
      let msg = match message_repo.get(message_id) {
        Ok(m) => m
        Err(_) => {
          assert_true(false)
          @shared.Message::new("", "", "", @shared.Public, @shared.ChatA, "")
        }
      }
      assert_eq(msg.origin, @shared.ChatA)
      assert_eq(msg.visibility, @shared.Public)
      assert_eq(msg.idempotency_key, "inbound:direct4b:ext_001")
    }
    _ => assert_true(false)
  }
}

///|
test "ingest_incoming deduplicates by platform and external_id" {
  let ticket_repo = TicketRepository::new()
  let message_repo = MessageRepository::new()
  let ctx = IngestContext::new(ticket_repo, message_repo, id_gen(), test_now)
  let inbound = @shared.InboundMessage::new(
    "ext_002", "direct4b", "room_001", "user_001", "alice", "same event", "2026-02-16T01:00:00Z",
  )
  let first = ingest_incoming(ctx, inbound)
  assert_true(first is Ok(Created(_, _)))
  let second = ingest_incoming(ctx, inbound)
  match second {
    Ok(DuplicateIgnored(ticket_id, message_id)) => {
      assert_true(ticket_id != "")
      assert_true(message_id != "")
      assert_eq(message_repo.list_by_ticket(ticket_id).length(), 1)
    }
    _ => assert_true(false)
  }
}

///|
test "ingest_incoming reuses existing ticket by platform+channel" {
  let ticket_repo = TicketRepository::new()
  let message_repo = MessageRepository::new()
  let ctx = IngestContext::new(ticket_repo, message_repo, id_gen(), test_now)
  let first = @shared.InboundMessage::new(
    "ext_100", "direct4b", "room_ABC", "user_001", "alice", "first", "2026-02-16T01:00:00Z",
  )
  let second = @shared.InboundMessage::new(
    "ext_101", "direct4b", "room_ABC", "user_002", "bob", "second", "2026-02-16T01:01:00Z",
  )
  let first_result = ingest_incoming(ctx, first)
  let first_ticket = match first_result {
    Ok(Created(ticket_id, _)) => ticket_id
    _ => {
      assert_true(false)
      ""
    }
  }
  let second_result = ingest_incoming(ctx, second)
  match second_result {
    Ok(Created(ticket_id, _)) => assert_eq(ticket_id, first_ticket)
    _ => assert_true(false)
  }
  assert_eq(ticket_repo.list().length(), 1)
  assert_eq(message_repo.list_by_ticket(first_ticket).length(), 2)
}
