///|
/// Inbound ingest result.
pub(all) enum IngestResult {
  Created(String, String) // (ticket_id, message_id)
  DuplicateIgnored(String, String) // (ticket_id, message_id)
} derive(Show, Eq)

///|
/// Inbound ingest errors.
pub(all) enum IngestError {
  InvalidInput(String)
  PersistenceFailed(String)
} derive(Show, Eq)

///|
/// Dependencies required for inbound ingest.
pub(all) struct IngestContext {
  ticket_repo : TicketRepository
  message_repo : MessageRepository
  route_binding_repo : RouteBindingRepository
  generate_id : () -> String
  current_timestamp : () -> String
}

///|
/// Build a context for ingesting inbound chat messages.
pub fn IngestContext::new(
  ticket_repo : TicketRepository,
  message_repo : MessageRepository,
  generate_id : () -> String,
  current_timestamp : () -> String,
  route_binding_repo? : RouteBindingRepository = RouteBindingRepository::new(),
) -> IngestContext {
  {
    ticket_repo,
    message_repo,
    route_binding_repo,
    generate_id,
    current_timestamp,
  }
}

///|
fn inbound_key(message : @shared.InboundMessage) -> String {
  "inbound:\{message.platform}:\{message.bot_account_id}:\{message.external_id}"
}

///|
fn is_blank_text(text : String) -> Bool {
  for c in text {
    if c != ' ' && c != '\n' && c != '\r' && c != '\t' {
      return false
    }
  }
  true
}

///|
fn ticket_subject(text : String) -> String {
  if is_blank_text(text) {
    return "Inbound message"
  }
  let sb = StringBuilder::new(size_hint=text.length())
  for c in text {
    if c == '\n' || c == '\r' {
      break
    }
    sb.write_char(c)
  }
  let out = sb.to_string().trim().to_string()
  if out == "" {
    "Inbound message"
  } else {
    out
  }
}

///|
fn find_ticket_by_channel(
  ticket_repo : TicketRepository,
  group_id : String,
  platform : String,
  channel_id : String,
) -> @shared.Ticket? {
  for t in ticket_repo.list() {
    if t.group_id == group_id &&
      t.chat_a.platform == platform &&
      t.chat_a.dm_id == channel_id &&
      t.status != @shared.Closed {
      return Some(t)
    }
  }
  None
}

///|
fn resolve_group_id(
  ctx : IngestContext,
  inbound : @shared.InboundMessage,
) -> Result[String, IngestError] {
  let default_group = @shared.default_group_id()
  if inbound.bot_account_id == "" {
    return Ok(default_group)
  }
  match
    ctx.route_binding_repo.resolve(
      inbound.platform,
      inbound.bot_account_id,
      inbound.channel_id,
    ) {
    Some(binding) => Ok(binding.group_id)
    None =>
      Err(
        InvalidInput(
          "route binding not found for platform=\{inbound.platform}, bot=\{inbound.bot_account_id}, channel=\{inbound.channel_id}",
        ),
      )
  }
}

///|
fn record_inbound_log(
  _ctx : IngestContext,
  _ticket_id : String,
  _message_id : String,
  _message : @shared.InboundMessage,
  _created_at : String,
) -> Unit {
  ()
}

///|
/// Ingest inbound message from chat service into ticket/message stores.
pub fn ingest_incoming(
  ctx : IngestContext,
  inbound : @shared.InboundMessage,
) -> Result[IngestResult, IngestError] {
  if inbound.platform == "" ||
    inbound.channel_id == "" ||
    inbound.external_id == "" {
    return Err(InvalidInput("platform/channel_id/external_id are required"))
  }
  let group_id = match resolve_group_id(ctx, inbound) {
    Ok(id) => id
    Err(err) => return Err(err)
  }
  let dedupe_key = inbound_key(inbound)
  match ctx.message_repo.get_by_idempotency_key(dedupe_key) {
    Some(existing) =>
      return Ok(DuplicateIgnored(existing.ticket_id, existing.message_id))
    None => ()
  }

  let now = (ctx.current_timestamp)()
  let ticket = match
    find_ticket_by_channel(
      ctx.ticket_repo,
      group_id,
      inbound.platform,
      inbound.channel_id,
    ) {
    Some(existing) => existing
    None => {
      let ticket_id = (ctx.generate_id)()
      let created = @shared.Ticket::{
        ..@shared.Ticket::new(
          ticket_id,
          ticket_subject(inbound.text),
          @shared.ChatAMetadata::new(
            inbound.platform,
            inbound.channel_id,
            inbound.external_id,
            bot_account_id=inbound.bot_account_id,
          ),
          group_id~,
        ),
        created_at: now,
        updated_at: now,
      }
      match ctx.ticket_repo.create(created) {
        Ok(_) => created
        Err(err) => return Err(PersistenceFailed(err.to_string()))
      }
    }
  }

  let updated_ticket = @shared.Ticket::{
    ..ticket,
    chat_a: @shared.ChatAMetadata::{
      ..ticket.chat_a,
      last_inbound_cursor: inbound.external_id,
    },
    updated_at: now,
  }
  match ctx.ticket_repo.update(updated_ticket) {
    Ok(_) => ()
    Err(err) => return Err(PersistenceFailed(err.to_string()))
  }

  let message_id = (ctx.generate_id)()
  let sender_name = if inbound.sender_name == "" {
    inbound.sender_id
  } else {
    inbound.sender_name
  }
  let inbound_message = @shared.Message::{
    ..@shared.Message::new(
      message_id,
      ticket.ticket_id,
      inbound.text,
      @shared.Public,
      @shared.ChatA,
      inbound.sender_id,
      group_id~,
    ),
    sender_name,
    timestamp: if inbound.timestamp == "" {
      now
    } else {
      inbound.timestamp
    },
    attachments: inbound.attachments,
    reply_to_message_id: inbound.reply_to_id,
    idempotency_key: dedupe_key,
  }
  match ctx.message_repo.create(inbound_message) {
    Ok(_) => {
      record_inbound_log(ctx, ticket.ticket_id, message_id, inbound, now)
      Ok(Created(ticket.ticket_id, message_id))
    }
    Err(err) => Err(PersistenceFailed(err.to_string()))
  }
}
