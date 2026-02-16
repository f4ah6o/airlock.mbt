///|
/// Log store backed by DuckDB.
pub(all) struct LogStore {
  conn : @duckdb.Connection
}

///|
/// Log store errors.
pub(all) enum LogStoreError {
  DuckDB(String)
} derive(Show, Eq)

///|
/// Result of persisting an inbound message.
pub(all) enum InboundPersistResult {
  Created(String, String) // (ticket_id, message_id)
  DuplicateIgnored(String, String) // (ticket_id, message_id)
} derive(Show, Eq)

///|
/// Open a DuckDB-backed log store and ensure schema exists.
pub fn LogStore::open(
  on_ready~ : (Result[LogStore, LogStoreError]) -> Unit,
  path? : String = "airlock_logs.duckdb",
  backend? : @duckdb.JsBackend = @duckdb.JsBackend::Auto,
) -> Unit {
  @duckdb.connect(
    on_ready=fn(result) {
      match result {
        Ok(conn) => ensure_schema(conn, on_ready)
        Err(err) => on_ready(Err(DuckDB(duckdb_error_message(err))))
      }
    },
    path~,
    backend~,
  )
}

///|
/// Append a log entry.
pub fn LogStore::append_entry(
  self : LogStore,
  entry : @shared.LogEntry,
  on_complete? : (Result[Unit, LogStoreError]) -> Unit,
) -> Unit {
  let sql = "insert into airlock_logs (log_id, ticket_id, event_type, entity_type, entity_id, actor_id, payload_json, created_at) values (" +
    sql_literal(entry.log_id) +
    ", " +
    sql_literal(entry.ticket_id) +
    ", " +
    sql_literal(entry.event_type) +
    ", " +
    sql_literal(entry.entity_type) +
    ", " +
    sql_literal(entry.entity_id) +
    ", " +
    sql_literal(entry.actor_id) +
    ", " +
    sql_literal(entry.payload_json) +
    ", " +
    sql_literal(entry.created_at) +
    ")"
  self.conn.query(sql, on_done=fn(result) {
    let outcome = match result {
      Ok(_) => Ok(())
      Err(err) => Err(DuckDB(duckdb_error_message(err)))
    }
    match on_complete {
      Some(done) => done(outcome)
      None => ()
    }
  })
}

///|
/// List recent log entries in reverse chronological order.
pub fn LogStore::list_recent(
  self : LogStore,
  on_done~ : (Result[Array[@shared.LogEntry], LogStoreError]) -> Unit,
  limit? : Int = 50,
) -> Unit {
  let safe_limit = if limit <= 0 { 1 } else { limit }
  let sql = "select log_id, ticket_id, event_type, entity_type, entity_id, actor_id, payload_json, created_at from airlock_logs order by created_at desc limit " +
    safe_limit.to_string()
  self.conn.query(sql, on_done=fn(result) {
    match result {
      Ok(query_result) => on_done(Ok(log_entries_from_result(query_result)))
      Err(err) => on_done(Err(DuckDB(duckdb_error_message(err))))
    }
  })
}

///|
/// Close the underlying connection.
pub fn LogStore::close(
  self : LogStore,
  on_complete? : (Result[Unit, LogStoreError]) -> Unit,
) -> Unit {
  self.conn.close(on_done=fn(result) {
    let outcome = match result {
      Ok(_) => Ok(())
      Err(err) => Err(DuckDB(duckdb_error_message(err)))
    }
    match on_complete {
      Some(done) => done(outcome)
      None => ()
    }
  })
}

///|
/// Persist inbound chat message into tickets/messages/ledger and append audit log.
pub fn LogStore::persist_inbound(
  self : LogStore,
  inbound : @shared.InboundMessage,
  generate_id : () -> String,
  current_timestamp : () -> String,
  on_done~ : (Result[InboundPersistResult, LogStoreError]) -> Unit,
) -> Unit {
  if inbound.platform == "" ||
    inbound.channel_id == "" ||
    inbound.external_id == "" {
    on_done(Err(DuckDB("platform/channel_id/external_id are required")))
    return
  }
  self.conn.query("begin transaction", on_done=fn(begin_result) {
    match begin_result {
      Err(err) => on_done(Err(DuckDB(duckdb_error_message(err))))
      Ok(_) =>
        persist_inbound_after_begin(
          self.conn,
          inbound,
          generate_id,
          current_timestamp,
          on_done,
        )
    }
  })
}

///|
fn persist_inbound_after_begin(
  conn : @duckdb.Connection,
  inbound : @shared.InboundMessage,
  generate_id : () -> String,
  current_timestamp : () -> String,
  on_done : (Result[InboundPersistResult, LogStoreError]) -> Unit,
) -> Unit {
  let dedupe_sql = "select ticket_id, message_id from inbound_ledger where platform = " +
    sql_literal(inbound.platform) +
    " and external_id = " +
    sql_literal(inbound.external_id) +
    " limit 1"
  conn.query(dedupe_sql, on_done=fn(dedupe_result) {
    match dedupe_result {
      Err(err) => rollback_and_fail(conn, duckdb_error_message(err), on_done)
      Ok(rows) =>
        if rows.row_count() > 0 {
          let ticket_id = result_cell(rows, 0, 0)
          let message_id = result_cell(rows, 0, 1)
          commit_result(
            conn,
            Ok(DuplicateIgnored(ticket_id, message_id)),
            on_done,
          )
        } else {
          resolve_and_persist_new_inbound(
            conn, inbound, generate_id, current_timestamp, on_done,
          )
        }
    }
  })
}

///|
fn resolve_and_persist_new_inbound(
  conn : @duckdb.Connection,
  inbound : @shared.InboundMessage,
  generate_id : () -> String,
  current_timestamp : () -> String,
  on_done : (Result[InboundPersistResult, LogStoreError]) -> Unit,
) -> Unit {
  let lookup_ticket_sql = "select ticket_id from tickets where platform = " +
    sql_literal(inbound.platform) +
    " and channel_id = " +
    sql_literal(inbound.channel_id) +
    " limit 1"
  conn.query(lookup_ticket_sql, on_done=fn(lookup_result) {
    match lookup_result {
      Err(err) => rollback_and_fail(conn, duckdb_error_message(err), on_done)
      Ok(rows) => {
        let ticket_id = if rows.row_count() > 0 {
          result_cell(rows, 0, 0)
        } else {
          generate_id()
        }
        let now = current_timestamp()
        if rows.row_count() > 0 {
          persist_message_and_ledger(
            conn, ticket_id, inbound, generate_id, now, on_done,
          )
        } else {
          let create_ticket_sql = "insert into tickets (" +
            "ticket_id, status, subject, platform, channel_id, last_inbound_cursor, lock_version, created_at, updated_at" +
            ") values (" +
            sql_literal(ticket_id) +
            ", 'open', " +
            sql_literal(inbound_subject(inbound.text)) +
            ", " +
            sql_literal(inbound.platform) +
            ", " +
            sql_literal(inbound.channel_id) +
            ", " +
            sql_literal(inbound.external_id) +
            ", 1, " +
            sql_literal(now) +
            ", " +
            sql_literal(now) +
            ")"
          conn.query(create_ticket_sql, on_done=fn(insert_ticket_result) {
            match insert_ticket_result {
              Err(err) =>
                rollback_and_fail(conn, duckdb_error_message(err), on_done)
              Ok(_) =>
                persist_message_and_ledger(
                  conn, ticket_id, inbound, generate_id, now, on_done,
                )
            }
          })
        }
      }
    }
  })
}

///|
fn persist_message_and_ledger(
  conn : @duckdb.Connection,
  ticket_id : String,
  inbound : @shared.InboundMessage,
  generate_id : () -> String,
  now : String,
  on_done : (Result[InboundPersistResult, LogStoreError]) -> Unit,
) -> Unit {
  let message_id = generate_id()
  let ts = if inbound.timestamp == "" { now } else { inbound.timestamp }
  let insert_message_sql = "insert into messages (" +
    "message_id, ticket_id, platform, external_id, sender_id, sender_name, text, attachments_json, reply_to_id, visibility, origin, timestamp, raw_data" +
    ") values (" +
    sql_literal(message_id) +
    ", " +
    sql_literal(ticket_id) +
    ", " +
    sql_literal(inbound.platform) +
    ", " +
    sql_literal(inbound.external_id) +
    ", " +
    sql_literal(inbound.sender_id) +
    ", " +
    sql_literal(inbound.sender_name) +
    ", " +
    sql_literal(inbound.text) +
    ", " +
    sql_literal("[]") +
    ", " +
    sql_literal(inbound.reply_to_id) +
    ", 'public', 'chatA', " +
    sql_literal(ts) +
    ", " +
    sql_literal(inbound.raw_data) +
    ")"
  conn.query(insert_message_sql, on_done=fn(insert_message_result) {
    match insert_message_result {
      Err(err) => rollback_and_fail(conn, duckdb_error_message(err), on_done)
      Ok(_) => {
        let update_ticket_sql = "update tickets set last_inbound_cursor = " +
          sql_literal(inbound.external_id) +
          ", updated_at = " +
          sql_literal(now) +
          " where ticket_id = " +
          sql_literal(ticket_id)
        conn.query(update_ticket_sql, on_done=fn(update_ticket_result) {
          match update_ticket_result {
            Err(err) =>
              rollback_and_fail(conn, duckdb_error_message(err), on_done)
            Ok(_) => {
              let insert_ledger_sql = "insert into inbound_ledger (" +
                "platform, external_id, ticket_id, message_id, received_at" +
                ") values (" +
                sql_literal(inbound.platform) +
                ", " +
                sql_literal(inbound.external_id) +
                ", " +
                sql_literal(ticket_id) +
                ", " +
                sql_literal(message_id) +
                ", " +
                sql_literal(now) +
                ")"
              conn.query(insert_ledger_sql, on_done=fn(insert_ledger_result) {
                match insert_ledger_result {
                  Err(err) =>
                    rollback_and_fail(conn, duckdb_error_message(err), on_done)
                  Ok(_) => {
                    let log_id = generate_id()
                    let insert_log_sql = "insert into airlock_logs (" +
                      "log_id, ticket_id, event_type, entity_type, entity_id, actor_id, payload_json, created_at" +
                      ") values (" +
                      sql_literal(log_id) +
                      ", " +
                      sql_literal(ticket_id) +
                      ", 'message_ingested', 'message', " +
                      sql_literal(message_id) +
                      ", " +
                      sql_literal(inbound.sender_id) +
                      ", " +
                      sql_literal(
                        "{\"platform\":\"\{inbound.platform}\",\"external_id\":\"\{inbound.external_id}\",\"channel_id\":\"\{inbound.channel_id}\"}",
                      ) +
                      ", " +
                      sql_literal(now) +
                      ")"
                    conn.query(insert_log_sql, on_done=fn(insert_log_result) {
                      match insert_log_result {
                        Err(err) =>
                          rollback_and_fail(
                            conn,
                            duckdb_error_message(err),
                            on_done,
                          )
                        Ok(_) =>
                          commit_result(
                            conn,
                            Ok(Created(ticket_id, message_id)),
                            on_done,
                          )
                      }
                    })
                  }
                }
              })
            }
          }
        })
      }
    }
  })
}

///|
fn rollback_and_fail(
  conn : @duckdb.Connection,
  message : String,
  on_done : (Result[InboundPersistResult, LogStoreError]) -> Unit,
) -> Unit {
  conn.query("rollback", on_done=fn(_) { on_done(Err(DuckDB(message))) })
}

///|
fn commit_result(
  conn : @duckdb.Connection,
  result : Result[InboundPersistResult, LogStoreError],
  on_done : (Result[InboundPersistResult, LogStoreError]) -> Unit,
) -> Unit {
  conn.query("commit", on_done=fn(commit_result) {
    match commit_result {
      Ok(_) => on_done(result)
      Err(err) => on_done(Err(DuckDB(duckdb_error_message(err))))
    }
  })
}

///|
fn ensure_schema(
  conn : @duckdb.Connection,
  on_done : (Result[LogStore, LogStoreError]) -> Unit,
) -> Unit {
  run_schema_queries(conn, schema_queries(), 0, on_done)
}

///|
fn run_schema_queries(
  conn : @duckdb.Connection,
  sqls : Array[String],
  idx : Int,
  on_done : (Result[LogStore, LogStoreError]) -> Unit,
) -> Unit {
  if idx >= sqls.length() {
    on_done(Ok(LogStore::{ conn, }))
    return
  }
  conn.query(sqls[idx], on_done=fn(result) {
    match result {
      Ok(_) => run_schema_queries(conn, sqls, idx + 1, on_done)
      Err(err) => on_done(Err(DuckDB(duckdb_error_message(err))))
    }
  })
}

///|
fn schema_queries() -> Array[String] {
  [
    "create table if not exists airlock_logs (" +
    "log_id text, " +
    "ticket_id text, " +
    "event_type text, " +
    "entity_type text, " +
    "entity_id text, " +
    "actor_id text, " +
    "payload_json text, " +
    "created_at text" +
    ")",
    "create table if not exists tickets (" +
    "ticket_id text primary key, " +
    "status text, " +
    "subject text, " +
    "platform text, " +
    "channel_id text, " +
    "last_inbound_cursor text, " +
    "lock_version integer, " +
    "created_at text, " +
    "updated_at text, " +
    "unique(platform, channel_id)" +
    ")",
    "create table if not exists messages (" +
    "message_id text primary key, " +
    "ticket_id text, " +
    "platform text, " +
    "external_id text, " +
    "sender_id text, " +
    "sender_name text, " +
    "text text, " +
    "attachments_json text, " +
    "reply_to_id text, " +
    "visibility text, " +
    "origin text, " +
    "timestamp text, " +
    "raw_data text, " +
    "unique(platform, external_id)" +
    ")",
    "create table if not exists inbound_ledger (" +
    "platform text, " +
    "external_id text, " +
    "ticket_id text, " +
    "message_id text, " +
    "received_at text, " +
    "primary key(platform, external_id)" +
    ")",
  ]
}

///|
fn inbound_subject(text : String) -> String {
  let mut out = ""
  let mut count = 0
  for c in text {
    if c == '\n' || c == '\r' {
      break
    }
    if count >= 80 {
      break
    }
    out = out + c.to_string()
    count = count + 1
  }
  if out == "" {
    "Inbound message"
  } else {
    out
  }
}

///|
fn sql_literal(value : String) -> String {
  "'" + escape_sql_string(value) + "'"
}

///|
fn escape_sql_string(value : String) -> String {
  let sb = StringBuilder::new(size_hint=value.length())
  for c in value {
    if c == '\'' {
      sb.write_char('\'')
      sb.write_char('\'')
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn log_entries_from_result(
  result : @duckdb.QueryResult,
) -> Array[@shared.LogEntry] {
  let entries : Array[@shared.LogEntry] = []
  for row = 0; row < result.row_count(); row = row + 1 {
    entries.push(log_entry_from_row(result, row))
  } nobreak {
    ()
  }
  entries
}

///|
fn log_entry_from_row(
  result : @duckdb.QueryResult,
  row : Int,
) -> @shared.LogEntry {
  let log_id = result_cell(result, row, 0)
  let ticket_id = result_cell(result, row, 1)
  let event_type = result_cell(result, row, 2)
  let entity_type = result_cell(result, row, 3)
  let entity_id = result_cell(result, row, 4)
  let actor_id = result_cell(result, row, 5)
  let payload_json = result_cell(result, row, 6)
  let created_at = result_cell(result, row, 7)
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

///|
fn result_cell(result : @duckdb.QueryResult, row : Int, col : Int) -> String {
  match result.cell(row, col) {
    Some(value) => value
    None => ""
  }
}

///|
fn duckdb_error_message(err : @duckdb.DuckDBError) -> String {
  match err {
    @duckdb.DuckDBError::Message(message) => message
  }
}
