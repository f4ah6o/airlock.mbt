///|
/// Authentication and authorization helpers for Keycloak-backed deployments.

///|
pub(all) enum AuthError {
  MissingIdentity
  Unauthorized(String)
  Forbidden(String)
  InvalidGroup(String)
  InvalidConfig(String)
} derive(Show, Eq)

///|
pub(all) struct AuthConfig {
  keycloak_issuer : String
  keycloak_realm : String
  keycloak_client_id : String
  keycloak_auth_base_url : String
  public_base_url : String
  strict_mode : Bool
  header_user_id : String
  header_email : String
  header_name : String
  header_subject : String
  header_groups : String
  header_roles : String
} derive(Show, Eq)

///|
pub fn AuthConfig::default() -> AuthConfig {
  {
    keycloak_issuer: "",
    keycloak_realm: "",
    keycloak_client_id: "airlock-web",
    keycloak_auth_base_url: "",
    public_base_url: "",
    strict_mode: true,
    header_user_id: "X-Auth-User",
    header_email: "X-Auth-Email",
    header_name: "X-Auth-Name",
    header_subject: "X-Auth-Subject",
    header_groups: "X-Auth-Groups",
    header_roles: "X-Auth-Group-Roles",
  }
}

///|
pub(all) struct Principal {
  identity : @shared.Identity
  group_ids : Array[String]
  group_roles : Map[String, Array[@shared.GroupRole]]
  raw_token : String
} derive(Show, Eq)

///|
pub fn Principal::is_group_member(self : Principal, group_id : String) -> Bool {
  self.group_ids.contains(group_id)
}

///|
fn role_set_for_group(
  principal : Principal,
  group_id : String,
) -> Array[@shared.GroupRole] {
  match principal.group_roles.get(group_id) {
    Some(roles) => roles
    None => []
  }
}

///|
fn has_role(roles : Array[@shared.GroupRole], role : @shared.GroupRole) -> Bool {
  roles.contains(role)
}

///|
pub fn Principal::can_post(self : Principal, group_id : String) -> Bool {
  if !self.is_group_member(group_id) {
    return false
  }
  let roles = role_set_for_group(self, group_id)
  has_role(roles, @shared.Owner) ||
  has_role(roles, @shared.Manager) ||
  has_role(roles, @shared.Agent)
}

///|
pub fn Principal::can_manage(self : Principal, group_id : String) -> Bool {
  if !self.is_group_member(group_id) {
    return false
  }
  let roles = role_set_for_group(self, group_id)
  has_role(roles, @shared.Owner) || has_role(roles, @shared.Manager)
}

///|
fn trim(text : String) -> String {
  text.trim().to_string()
}

///|
fn parse_csv(csv : String) -> Array[String] {
  if csv == "" {
    return []
  }
  let out : Array[String] = []
  for seg in csv.split(",") {
    let v = trim(seg.to_string())
    if v != "" {
      out.push(v)
    }
  }
  out
}

///|
fn substring(text : String, start : Int, end_ : Int) -> String {
  let sb = StringBuilder::new(size_hint=end_ - start)
  for i in start..<end_ {
    sb.write_char(text[i].unsafe_to_char())
  }
  sb.to_string()
}

///|
fn split_once(text : String, delimiter : UInt16) -> (String, String)? {
  for i in 0..<text.length() {
    if text[i] == delimiter {
      let left = substring(text, 0, i)
      let right = substring(text, i + 1, text.length())
      return Some((left, right))
    }
  }
  None
}

///|
fn parse_role(role_text : String) -> @shared.GroupRole? {
  let lower = trim(role_text).to_lower()
  if lower == "owner" {
    return Some(@shared.Owner)
  }
  if lower == "manager" {
    return Some(@shared.Manager)
  }
  if lower == "agent" {
    return Some(@shared.Agent)
  }
  if lower == "viewer" {
    return Some(@shared.Viewer)
  }
  None
}

///|
fn parse_group_roles(value : String) -> Map[String, Array[@shared.GroupRole]] {
  // Format: grpA:owner|agent,grpB:viewer
  let out : Map[String, Array[@shared.GroupRole]] = {}
  if value == "" {
    return out
  }
  for segment in value.split(",") {
    let entry = trim(segment.to_string())
    if entry == "" {
      continue
    }
    match split_once(entry, ':') {
      None => ()
      Some((group_id, roles_raw)) => {
        let gid = trim(group_id)
        if gid == "" {
          continue
        }
        let roles : Array[@shared.GroupRole] = []
        for role_seg in roles_raw.split("|") {
          match parse_role(role_seg.to_string()) {
            Some(role) => if !roles.contains(role) { roles.push(role) }
            None => ()
          }
        }
        if !roles.is_empty() {
          out.set(gid, roles)
        }
      }
    }
  }
  out
}

///|
fn ascii_lower_u16(c : UInt16) -> Int {
  let code = c.to_int()
  if code >= 65 && code <= 90 {
    return code + 32
  }
  code
}

///|
fn ascii_eq_ignore_case(a : String, b : String) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if ascii_lower_u16(a[i]) != ascii_lower_u16(b[i]) {
      return false
    }
  }
  true
}

///|
fn header_value(headers : Array[(String, String)], name : String) -> String {
  for header in headers {
    let (k, v) = header
    if ascii_eq_ignore_case(k, name) {
      return trim(v)
    }
  }
  ""
}

///|
fn merge_role_defaults(
  groups : Array[String],
  role_map : Map[String, Array[@shared.GroupRole]],
) -> Map[String, Array[@shared.GroupRole]] {
  for gid in groups {
    if role_map.get(gid) is None {
      role_map.set(gid, [@shared.Viewer])
    }
  }
  role_map
}

///|
pub fn principal_from_headers(
  config : AuthConfig,
  headers : Array[(String, String)],
) -> Result[Principal, AuthError] {
  let user_id = header_value(headers, config.header_user_id)
  if user_id == "" {
    return if config.strict_mode {
      Err(MissingIdentity)
    } else {
      Err(Unauthorized("missing authenticated user header"))
    }
  }
  let email = header_value(headers, config.header_email)
  let display_name = {
    let v = header_value(headers, config.header_name)
    if v == "" {
      user_id
    } else {
      v
    }
  }
  let sub = header_value(headers, config.header_subject)
  let groups = parse_csv(header_value(headers, config.header_groups))
  let roles = parse_group_roles(header_value(headers, config.header_roles))
  let merged_roles = merge_role_defaults(groups, roles)
  Ok({
    identity: @shared.Identity::new(user_id, email, display_name, sub),
    group_ids: groups,
    group_roles: merged_roles,
    raw_token: "",
  })
}

///|
pub fn require_group_access(
  principal : Principal,
  group_id : String,
  write? : Bool = false,
) -> Result[Unit, AuthError] {
  if group_id == "" {
    return Err(InvalidGroup("group_id is required"))
  }
  if !principal.is_group_member(group_id) {
    return Err(Forbidden("user is not a member of group \{group_id}"))
  }
  if write && !principal.can_post(group_id) {
    return Err(
      Forbidden("user has no posting permission for group \{group_id}"),
    )
  }
  Ok(())
}

///|
fn url_encode_component(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length() + 16)
  for c in text {
    let code = c.to_int()
    let is_alpha_num = (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122)
    let is_safe = is_alpha_num || c == '-' || c == '_' || c == '.' || c == '~'
    if is_safe {
      sb.write_char(c)
    } else {
      sb.write_char('%')
      let hi = (code / 16) & 0xF
      let lo = code & 0xF
      sb.write_char(
        if hi < 10 {
          Int::unsafe_to_char(48 + hi)
        } else {
          Int::unsafe_to_char(65 + hi - 10)
        },
      )
      sb.write_char(
        if lo < 10 {
          Int::unsafe_to_char(48 + lo)
        } else {
          Int::unsafe_to_char(65 + lo - 10)
        },
      )
    }
  }
  sb.to_string()
}

///|
pub fn build_keycloak_login_url(
  config : AuthConfig,
  return_to : String,
) -> String {
  if config.keycloak_auth_base_url == "" || config.keycloak_client_id == "" {
    return ""
  }
  let redirect_uri = if config.public_base_url == "" {
    ""
  } else {
    config.public_base_url + "/auth/callback"
  }
  config.keycloak_auth_base_url +
  "?client_id=" +
  url_encode_component(config.keycloak_client_id) +
  "&response_type=code&scope=openid&redirect_uri=" +
  url_encode_component(redirect_uri) +
  "&kc_idp_hint=passkey&state=" +
  url_encode_component(return_to)
}
