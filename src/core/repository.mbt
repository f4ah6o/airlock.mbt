///|
/// Repository error types
pub(all) enum RepositoryError {
  NotFound(String)
  DuplicateKey(String)
  ConcurrencyConflict(String)
  ValidationError(String)
} derive(Show, Eq)

///|
/// In-memory Ticket repository
pub(all) struct TicketRepository {
  tickets : Map[String, @shared.Ticket]
}

///|
/// Create a new TicketRepository
pub fn TicketRepository::new() -> TicketRepository {
  { tickets: {} }
}

///|
/// Create a ticket
pub fn TicketRepository::create(
  self : TicketRepository,
  ticket : @shared.Ticket
) -> Result[Unit, RepositoryError] {
  if self.tickets.contains(ticket.ticket_id) {
    return Err(DuplicateKey("Ticket with ID \{ticket.ticket_id} already exists"))
  }
  self.tickets.set(ticket.ticket_id, ticket)
  Ok(())
}

///|
/// Get a ticket by ID
pub fn TicketRepository::get(
  self : TicketRepository,
  ticket_id : String
) -> Result[@shared.Ticket, RepositoryError] {
  match self.tickets.get(ticket_id) {
    Some(ticket) => Ok(ticket)
    None => Err(NotFound("Ticket \{ticket_id} not found"))
  }
}

///|
/// Update a ticket with optimistic locking
pub fn TicketRepository::update(
  self : TicketRepository,
  ticket : @shared.Ticket
) -> Result[Unit, RepositoryError] {
  match self.tickets.get(ticket.ticket_id) {
    None => Err(NotFound("Ticket \{ticket.ticket_id} not found"))
    Some(existing) =>
      if existing.lock_version != ticket.lock_version {
        Err(
          ConcurrencyConflict(
            "Ticket \{ticket.ticket_id} was modified by another user",
          ),
        )
      } else {
        let updated = @shared.Ticket::{ ..ticket, lock_version: ticket.lock_version + 1 }
        self.tickets.set(ticket.ticket_id, updated)
        Ok(())
      }
  }
}

///|
/// Delete a ticket
pub fn TicketRepository::delete(
  self : TicketRepository,
  ticket_id : String
) -> Result[Unit, RepositoryError] {
  if not(self.tickets.contains(ticket_id)) {
    return Err(NotFound("Ticket \{ticket_id} not found"))
  }
  self.tickets.remove(ticket_id)
  Ok(())
}

///|
/// List all tickets
pub fn TicketRepository::list(
  self : TicketRepository
) -> Array[@shared.Ticket] {
  self.tickets.values().collect()
}

///|
/// List tickets by status
pub fn TicketRepository::list_by_status(
  self : TicketRepository,
  status : @shared.TicketStatus
) -> Array[@shared.Ticket] {
  self.tickets.values().filter(fn(t) { t.status == status }).collect()
}

///|
/// In-memory Message repository
pub(all) struct MessageRepository {
  messages : Map[String, @shared.Message]
  // Index for quick lookup by ticket
  by_ticket : Map[String, Array[String]]
  // Idempotency key tracking
  idempotency_keys : Map[String, String] // key -> message_id
}

///|
/// Create a new MessageRepository
pub fn MessageRepository::new() -> MessageRepository {
  { messages: {}, by_ticket: {}, idempotency_keys: {} }
}

///|
/// Create a message
pub fn MessageRepository::create(
  self : MessageRepository,
  message : @shared.Message
) -> Result[Unit, RepositoryError] {
  // Check duplicate message ID
  if self.messages.contains(message.message_id) {
    return Err(
      DuplicateKey("Message with ID \{message.message_id} already exists"),
    )
  }

  // Check idempotency key
  if message.idempotency_key != "" &&
    self.idempotency_keys.contains(message.idempotency_key) {
    return Err(
      DuplicateKey(
        "Message with idempotency key \{message.idempotency_key} already exists",
      ),
    )
  }

  // Store message
  self.messages.set(message.message_id, message)

  // Update ticket index
  match self.by_ticket.get(message.ticket_id) {
    Some(ids) => ids.push(message.message_id)
    None => self.by_ticket.set(message.ticket_id, [message.message_id])
  }

  // Track idempotency key
  if message.idempotency_key != "" {
    self.idempotency_keys.set(message.idempotency_key, message.message_id)
  }
  Ok(())
}

///|
/// Get a message by ID
pub fn MessageRepository::get(
  self : MessageRepository,
  message_id : String
) -> Result[@shared.Message, RepositoryError] {
  match self.messages.get(message_id) {
    Some(msg) => Ok(msg)
    None => Err(NotFound("Message \{message_id} not found"))
  }
}

///|
/// Get message by idempotency key
pub fn MessageRepository::get_by_idempotency_key(
  self : MessageRepository,
  key : String
) -> @shared.Message? {
  match self.idempotency_keys.get(key) {
    Some(msg_id) => self.messages.get(msg_id)
    None => None
  }
}

///|
/// Update a message
pub fn MessageRepository::update(
  self : MessageRepository,
  message : @shared.Message
) -> Result[Unit, RepositoryError] {
  if not(self.messages.contains(message.message_id)) {
    return Err(NotFound("Message \{message.message_id} not found"))
  }
  self.messages.set(message.message_id, message)
  Ok(())
}

///|
/// Delete a message
pub fn MessageRepository::delete(
  self : MessageRepository,
  message_id : String
) -> Result[Unit, RepositoryError] {
  match self.messages.get(message_id) {
    None => Err(NotFound("Message \{message_id} not found"))
    Some(msg) => {
      self.messages.remove(message_id)
      // Remove from ticket index
      match self.by_ticket.get(msg.ticket_id) {
        Some(ids) => {
          let filtered = ids.filter(fn(id) { id != message_id })
          self.by_ticket.set(msg.ticket_id, filtered)
        }
        None => ()
      }
      // Remove idempotency key
      if msg.idempotency_key != "" {
        self.idempotency_keys.remove(msg.idempotency_key)
      }
      Ok(())
    }
  }
}

///|
/// List all messages for a ticket
pub fn MessageRepository::list_by_ticket(
  self : MessageRepository,
  ticket_id : String
) -> Array[@shared.Message] {
  match self.by_ticket.get(ticket_id) {
    None => []
    Some(ids) =>
      ids
      .iter()
      .filter_map(fn(id) { self.messages.get(id) })
      .collect()
  }
}

///|
/// List public messages for a ticket (Timeline view)
pub fn MessageRepository::list_public_by_ticket(
  self : MessageRepository,
  ticket_id : String
) -> Array[@shared.Message] {
  self
  .list_by_ticket(ticket_id)
  .filter(fn(m) { m.visibility == @shared.Public })
}

///|
/// List all messages for workspace view (internal + public)
pub fn MessageRepository::list_workspace_by_ticket(
  self : MessageRepository,
  ticket_id : String
) -> Array[@shared.Message] {
  self.list_by_ticket(ticket_id)
}

///|
/// List draft messages for a ticket
pub fn MessageRepository::list_drafts_by_ticket(
  self : MessageRepository,
  ticket_id : String
) -> Array[@shared.Message] {
  self.list_by_ticket(ticket_id).filter(fn(m) { m.is_draft })
}

///|
/// Check if idempotency key exists
pub fn MessageRepository::has_idempotency_key(
  self : MessageRepository,
  key : String
) -> Bool {
  self.idempotency_keys.contains(key)
}
