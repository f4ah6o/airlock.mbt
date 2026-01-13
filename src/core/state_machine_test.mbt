///|
test "valid state transitions" {
  // Pending -> Checking
  assert_true(
    is_valid_transition(
      @shared.DraftStatus::Pending,
      @shared.DraftStatus::Checking,
    ),
  )

  // Checking -> Checked
  assert_true(
    is_valid_transition(
      @shared.DraftStatus::Checking,
      @shared.DraftStatus::Checked,
    ),
  )

  // Checking -> Rejected
  assert_true(
    is_valid_transition(
      @shared.DraftStatus::Checking,
      @shared.DraftStatus::Rejected,
    ),
  )

  // Checked -> Published
  assert_true(
    is_valid_transition(
      @shared.DraftStatus::Checked,
      @shared.DraftStatus::Published,
    ),
  )

  // Rejected -> Pending (retry)
  assert_true(
    is_valid_transition(
      @shared.DraftStatus::Rejected,
      @shared.DraftStatus::Pending,
    ),
  )

  // Rejected -> Checking (direct recheck)
  assert_true(
    is_valid_transition(
      @shared.DraftStatus::Rejected,
      @shared.DraftStatus::Checking,
    ),
  )
}

///|
test "invalid state transitions" {
  // Cannot skip checking
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Pending,
      @shared.DraftStatus::Checked,
    ),
  )
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Pending,
      @shared.DraftStatus::Published,
    ),
  )

  // Cannot publish from wrong states
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Pending,
      @shared.DraftStatus::Published,
    ),
  )
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Checking,
      @shared.DraftStatus::Published,
    ),
  )
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Rejected,
      @shared.DraftStatus::Published,
    ),
  )

  // Cannot go back from published
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Published,
      @shared.DraftStatus::Pending,
    ),
  )
  assert_false(
    is_valid_transition(
      @shared.DraftStatus::Published,
      @shared.DraftStatus::Checking,
    ),
  )
}

///|
test "can_publish" {
  assert_false(can_publish(@shared.DraftStatus::Pending))
  assert_false(can_publish(@shared.DraftStatus::Checking))
  assert_true(can_publish(@shared.DraftStatus::Checked))
  assert_false(can_publish(@shared.DraftStatus::Rejected))
  assert_false(can_publish(@shared.DraftStatus::Published))
}

///|
test "is_final_state" {
  assert_false(is_final_state(@shared.DraftStatus::Pending))
  assert_false(is_final_state(@shared.DraftStatus::Checking))
  assert_false(is_final_state(@shared.DraftStatus::Checked))
  assert_false(is_final_state(@shared.DraftStatus::Rejected))
  assert_true(is_final_state(@shared.DraftStatus::Published))
}

///|
test "can_edit" {
  assert_true(can_edit(@shared.DraftStatus::Pending))
  assert_false(can_edit(@shared.DraftStatus::Checking))
  assert_true(can_edit(@shared.DraftStatus::Checked))
  assert_true(can_edit(@shared.DraftStatus::Rejected))
  assert_false(can_edit(@shared.DraftStatus::Published))
}

///|
test "start_check success" {
  let draft = @shared.Message::new_draft(
    "msg_001", "tkt_001", "Test", "admin_001", "key_001",
  )
  let result = start_check(draft)
  match result {
    Ok(updated) => {
      assert_eq(updated.draft_status, @shared.DraftStatus::Checking)
      assert_true(updated.ai_check_result is None)
    }
    Err(_) => assert_true(false) // Should not fail
  }
}

///|
test "start_check non-draft fails" {
  let note = @shared.Message::new_note(
    "msg_001", "tkt_001", "Note", "admin_001",
  )
  let result = start_check(note)
  match result {
    Ok(_) => assert_true(false) // Should fail
    Err(e) =>
      match e {
        InvalidTransition(_) => assert_true(true)
        _ => assert_true(false)
      }
  }
}

///|
test "complete_check pass" {
  let draft = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Test", "admin_001", "key_001",
    ),
    draft_status: @shared.DraftStatus::Checking,
  }
  let check_result = @shared.AICheckResult::pass()
  let result = complete_check(draft, check_result)
  match result {
    Ok(updated) => {
      assert_eq(updated.draft_status, @shared.DraftStatus::Checked)
      assert_true(updated.ai_check_result is Some(_))
    }
    Err(_) => assert_true(false)
  }
}

///|
test "complete_check fail" {
  let draft = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Test", "admin_001", "key_001",
    ),
    draft_status: @shared.DraftStatus::Checking,
  }
  let check_result = @shared.AICheckResult::fail(["Issue found"])
  let result = complete_check(draft, check_result)
  match result {
    Ok(updated) =>
      assert_eq(updated.draft_status, @shared.DraftStatus::Rejected)
    Err(_) => assert_true(false)
  }
}

///|
test "publish_draft success" {
  let draft = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Test", "admin_001", "key_001",
    ),
    draft_status: @shared.DraftStatus::Checked,
  }
  let result = publish_draft(draft, "2025-01-09T12:00:00Z")
  match result {
    Ok(updated) => {
      assert_eq(updated.draft_status, @shared.DraftStatus::Published)
      assert_eq(updated.visibility, @shared.Visibility::Public)
      assert_eq(updated.published_at, "2025-01-09T12:00:00Z")
    }
    Err(_) => assert_true(false)
  }
}

///|
test "publish_draft not checked fails" {
  let draft = @shared.Message::new_draft(
    "msg_001", "tkt_001", "Test", "admin_001", "key_001",
  )
  let result = publish_draft(draft, "2025-01-09T12:00:00Z")
  match result {
    Ok(_) => assert_true(false)
    Err(e) =>
      match e {
        NotChecked => assert_true(true)
        _ => assert_true(false)
      }
  }
}

///|
test "publish_draft already published fails" {
  let draft = @shared.Message::{
    ..@shared.Message::new_draft(
      "msg_001", "tkt_001", "Test", "admin_001", "key_001",
    ),
    draft_status: @shared.DraftStatus::Checked,
    published_at: "2025-01-08T10:00:00Z",
  }
  let result = publish_draft(draft, "2025-01-09T12:00:00Z")
  match result {
    Ok(_) => assert_true(false)
    Err(e) =>
      match e {
        AlreadyPublished => assert_true(true)
        _ => assert_true(false)
      }
  }
}
