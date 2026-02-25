///|
fn base_headers() -> Array[(String, String)] {
  [
    ("X-Auth-User", "user-01"),
    ("X-Auth-Email", "user-01@example.com"),
    ("X-Auth-Name", "User One"),
    ("X-Auth-Subject", "sub-abc"),
    ("X-Auth-Groups", "grp-alpha,grp-beta"),
    ("X-Auth-Group-Roles", "grp-alpha:owner|agent,grp-beta:viewer"),
  ]
}

///|
test "principal_from_headers parses groups and roles" {
  let cfg = AuthConfig::default()
  let principal = match principal_from_headers(cfg, base_headers()) {
    Ok(v) => v
    Err(_) => {
      assert_true(false)
      {
        identity: @shared.Identity::new("", "", "", ""),
        group_ids: [],
        group_roles: {},
        raw_token: "",
      }
    }
  }
  assert_eq(principal.identity.user_id, "user-01")
  assert_true(principal.is_group_member("grp-alpha"))
  assert_true(principal.can_post("grp-alpha"))
  assert_false(principal.can_post("grp-beta"))
}

///|
test "principal_from_headers fails when missing identity" {
  let cfg = AuthConfig::default()
  let result = principal_from_headers(cfg, [])
  assert_true(result is Err(MissingIdentity))
}

///|
test "require_group_access validates membership and write permission" {
  let cfg = AuthConfig::default()
  let principal = match principal_from_headers(cfg, base_headers()) {
    Ok(v) => v
    Err(_) => {
      assert_true(false)
      {
        identity: @shared.Identity::new("", "", "", ""),
        group_ids: [],
        group_roles: {},
        raw_token: "",
      }
    }
  }
  assert_true(require_group_access(principal, "grp-alpha") is Ok(_))
  assert_true(require_group_access(principal, "grp-alpha", write=true) is Ok(_))
  assert_true(require_group_access(principal, "grp-beta", write=true) is Err(_))
  assert_true(require_group_access(principal, "grp-unknown") is Err(_))
}

///|
test "build_keycloak_login_url includes passkey hint and state" {
  let cfg = AuthConfig::{
    ..AuthConfig::default(),
    keycloak_auth_base_url: "https://sso.example.com/auth/realms/company/protocol/openid-connect/auth",
    keycloak_client_id: "airlock-web",
    public_base_url: "https://grp.obr-grp.com",
  }
  let url = build_keycloak_login_url(cfg, "/grp-alpha")
  assert_true(url.contains("kc_idp_hint=passkey"))
  assert_true(url.contains("state=%2Fgrp-alpha"))
}
