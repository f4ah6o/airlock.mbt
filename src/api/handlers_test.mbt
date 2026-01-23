///|
fn make_context() -> AppContext {
  let ticket_repo = @core.TicketRepository::new()
  let message_repo = @core.MessageRepository::new()
  let now = fn() { "2025-01-09T12:00:00Z" }
  let gen = fn() { "msg_001" }
  AppContext::new(ticket_repo, message_repo, now, gen)
}

///|
fn seed_ticket(ctx : AppContext, ticket_id : String) -> Unit {
  let chat_a = @shared.ChatAMetadata::new("direct4b", "dm_001", "ts_001")
  let ticket = @shared.Ticket::new(ticket_id, "Test Ticket", chat_a)
  let _ = ctx.ticket_repo.create(ticket)

}

///|
test "draft publish flow via handlers" {
  let ctx = make_context()
  let ticket_id = "tkt_001"
  seed_ticket(ctx, ticket_id)
  let draft_body = "{\"text\":\"Draft message\",\"idempotency_key\":\"key_001\"}"
  let draft_req = RequestContext::new(
    HttpMethod::Post,
    "/api/tickets/" + ticket_id + "/drafts",
    draft_body,
    "admin_001",
  )
  let draft_res = handle_create_draft(ctx, draft_req, ticket_id)
  assert_eq(draft_res.status_code, 201)
  let draft = match ctx.message_repo.get("msg_001") {
    Ok(msg) => msg
    Err(_) => {
      assert_true(false)
      @shared.Message::new(
        "",
        "",
        "",
        @shared.Visibility::Public,
        @shared.Origin::System,
        "",
      )
    }
  }
  let checked = @shared.Message::{
    ..draft,
    draft_status: @shared.DraftStatus::Checked,
  }
  let _ = ctx.message_repo.update(checked)
  let publish_req = RequestContext::{
    ..RequestContext::new(
      HttpMethod::Post,
      "/api/tickets/" + ticket_id + "/drafts/msg_001/publish",
      "{}",
      "admin_001",
    ),
    idempotency_key: "pub_key_001",
  }
  let publish_res = handle_publish_draft(ctx, publish_req, ticket_id, "msg_001")
  assert_eq(publish_res.status_code, 200)
  let published = match ctx.message_repo.get("msg_001") {
    Ok(msg) => msg
    Err(_) => {
      assert_true(false)
      @shared.Message::new(
        "",
        "",
        "",
        @shared.Visibility::Public,
        @shared.Origin::System,
        "",
      )
    }
  }
  assert_eq(published.visibility, @shared.Visibility::Public)
  assert_eq(published.draft_status, @shared.DraftStatus::Published)
  assert_eq(published.published_at, "2025-01-09T12:00:00Z")
}
