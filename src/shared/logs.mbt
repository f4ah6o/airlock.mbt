///|
/// Log entry for audit/event persistence.
pub(all) struct LogEntry {
  log_id : String
  ticket_id : String
  event_type : String
  entity_type : String
  entity_id : String
  actor_id : String
  payload_json : String
  created_at : String
} derive(Show, Eq)

///|
/// Create a new log entry.
pub fn LogEntry::new(
  log_id : String,
  ticket_id : String,
  event_type : String,
  entity_type : String,
  entity_id : String,
  actor_id : String,
  payload_json : String,
  created_at : String,
) -> LogEntry {
  {
    log_id,
    ticket_id,
    event_type,
    entity_type,
    entity_id,
    actor_id,
    payload_json,
    created_at,
  }
}
