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
fn ensure_schema(
  conn : @duckdb.Connection,
  on_done : (Result[LogStore, LogStoreError]) -> Unit,
) -> Unit {
  let sql = create_table_sql()
  conn.query(sql, on_done=fn(result) {
    match result {
      Ok(_) => on_done(Ok(LogStore::{ conn, }))
      Err(err) => on_done(Err(DuckDB(duckdb_error_message(err))))
    }
  })
}

///|
fn create_table_sql() -> String {
  "create table if not exists airlock_logs (" +
  "log_id text, " +
  "ticket_id text, " +
  "event_type text, " +
  "entity_type text, " +
  "entity_id text, " +
  "actor_id text, " +
  "payload_json text, " +
  "created_at text" +
  ")"
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
