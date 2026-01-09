///|
/// Draft status state machine implementation
///
/// State transitions:
/// [Draft Created] → pending
///      ↓
/// [AI Check Triggered] → checking
///      ↓
/// [Check Complete] → checked | rejected
///      ↓
/// [Publish Action] → published

/// Error types for state transitions
pub(all) enum StateTransitionError {
  InvalidTransition(String)
  AlreadyPublished
  NotChecked
  StillChecking
} derive(Show, Eq)

///|
/// Check if a draft status transition is valid
pub fn is_valid_transition(
  from : @shared.DraftStatus,
  to : @shared.DraftStatus
) -> Bool {
  match (from, to) {
    // From Pending: can start checking
    (@shared.Pending, @shared.Checking) => true
    // From Checking: can complete to checked or rejected
    (@shared.Checking, @shared.Checked) => true
    (@shared.Checking, @shared.Rejected) => true
    // From Checked: can publish
    (@shared.Checked, @shared.Published) => true
    // From Rejected: can retry checking
    (@shared.Rejected, @shared.Pending) => true
    (@shared.Rejected, @shared.Checking) => true
    // No other transitions allowed
    _ => false
  }
}

///|
/// Attempt to transition draft status
pub fn transition_draft_status(
  current : @shared.DraftStatus,
  target : @shared.DraftStatus
) -> Result[@shared.DraftStatus, StateTransitionError] {
  if is_valid_transition(current, target) {
    Ok(target)
  } else {
    let msg = "Cannot transition from \{current.to_string()} to \{target.to_string()}"
    Err(InvalidTransition(msg))
  }
}

///|
/// Check if a draft can be published
pub fn can_publish(status : @shared.DraftStatus) -> Bool {
  status == @shared.Checked
}

///|
/// Check if a draft is in a final state
pub fn is_final_state(status : @shared.DraftStatus) -> Bool {
  status == @shared.Published
}

///|
/// Check if a draft can be edited
pub fn can_edit(status : @shared.DraftStatus) -> Bool {
  match status {
    @shared.Pending => true
    @shared.Rejected => true
    @shared.Checked => true // Can edit, but will need recheck
    _ => false
  }
}

///|
/// Start AI check on a draft
pub fn start_check(
  message : @shared.Message
) -> Result[@shared.Message, StateTransitionError] {
  if not(message.is_draft) {
    return Err(InvalidTransition("Cannot check non-draft message"))
  }
  match transition_draft_status(message.draft_status, @shared.Checking) {
    Ok(new_status) => {
      let updated = @shared.Message::{
        ..message,
        draft_status: new_status,
        ai_check_result: None,
      }
      Ok(updated)
    }
    Err(e) => Err(e)
  }
}

///|
/// Complete AI check with result
pub fn complete_check(
  message : @shared.Message,
  result : @shared.AICheckResult
) -> Result[@shared.Message, StateTransitionError] {
  if message.draft_status != @shared.Checking {
    return Err(InvalidTransition("Can only complete check from checking state"))
  }
  let new_status = if result.passed {
    @shared.Checked
  } else {
    @shared.Rejected
  }
  let updated = @shared.Message::{
    ..message,
    draft_status: new_status,
    ai_check_result: Some(result),
  }
  Ok(updated)
}

///|
/// Publish a draft message
pub fn publish_draft(
  message : @shared.Message,
  published_at : String
) -> Result[@shared.Message, StateTransitionError] {
  if not(message.is_draft) {
    return Err(InvalidTransition("Cannot publish non-draft message"))
  }
  if message.published_at != "" {
    return Err(AlreadyPublished)
  }
  if not(can_publish(message.draft_status)) {
    return Err(NotChecked)
  }
  let updated = @shared.Message::{
    ..message,
    draft_status: @shared.Published,
    visibility: @shared.Public,
    published_at,
  }
  Ok(updated)
}

///|
/// Reset draft for editing (after rejection or for modification)
pub fn reset_for_edit(
  message : @shared.Message
) -> Result[@shared.Message, StateTransitionError] {
  if not(message.is_draft) {
    return Err(InvalidTransition("Cannot reset non-draft message"))
  }
  if is_final_state(message.draft_status) {
    return Err(AlreadyPublished)
  }
  let updated = @shared.Message::{
    ..message,
    draft_status: @shared.Pending,
    ai_check_result: None,
  }
  Ok(updated)
}
