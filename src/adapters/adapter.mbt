///|
/// Normalized message format for cross-platform compatibility
pub(all) struct NormalizedMessage {
  external_id : String // Platform-specific message ID
  platform : String // "direct", "slack", "discord", etc.
  channel_id : String // DM/Channel ID
  sender_id : String // Platform user ID
  sender_name : String // Display name
  text : String // Message content
  attachments : Array[@shared.Attachment]
  timestamp : String // ISO timestamp
  is_bot : Bool // Whether sender is a bot
  reply_to_id : String // For threading (empty if not reply)
  raw_data : String // Original JSON for debugging
} derive(Show, Eq)

///|
/// Create a new NormalizedMessage
pub fn NormalizedMessage::new(
  external_id : String,
  platform : String,
  channel_id : String,
  sender_id : String,
  sender_name : String,
  text : String,
  timestamp : String,
) -> NormalizedMessage {
  {
    external_id,
    platform,
    channel_id,
    sender_id,
    sender_name,
    text,
    attachments: [],
    timestamp,
    is_bot: false,
    reply_to_id: "",
    raw_data: "",
  }
}

///|
/// Convert adapter normalized message into shared inbound message.
pub fn NormalizedMessage::to_inbound(
  self : NormalizedMessage,
) -> @shared.InboundMessage {
  {
    external_id: self.external_id,
    platform: self.platform,
    channel_id: self.channel_id,
    sender_id: self.sender_id,
    sender_name: self.sender_name,
    text: self.text,
    attachments: self.attachments,
    timestamp: self.timestamp,
    reply_to_id: self.reply_to_id,
    raw_data: self.raw_data,
  }
}

///|
/// Outbound message to send via adapter
pub(all) struct OutboundMessage {
  channel_id : String // Target DM/Channel ID
  text : String // Message content
  attachments : Array[@shared.Attachment]
  reply_to_id : String // For threading (empty if not reply)
  idempotency_key : String // For deduplication
} derive(Show, Eq)

///|
pub(all) struct DownloadAuth {
  url : String
  headers : Map[String, String]
} derive(Show, Eq)

///|
/// Create a new OutboundMessage
pub fn OutboundMessage::new(
  channel_id : String,
  text : String,
  idempotency_key : String,
) -> OutboundMessage {
  { channel_id, text, attachments: [], reply_to_id: "", idempotency_key }
}

///|
/// Result of sending a message
pub(all) struct SendResult {
  success : Bool
  external_id : String // Platform message ID if successful
  error_message : String // Error description if failed
  timestamp : String // Send timestamp
} derive(Show, Eq)

///|
/// Create a successful SendResult
pub fn SendResult::success(
  external_id : String,
  timestamp : String,
) -> SendResult {
  { success: true, external_id, error_message: "", timestamp }
}

///|
/// Create a failed SendResult
pub fn SendResult::failure(error_message : String) -> SendResult {
  { success: false, external_id: "", error_message, timestamp: "" }
}

///|
/// Adapter error types
pub(all) enum AdapterError {
  ConnectionError(String)
  AuthenticationError(String)
  RateLimitError(String)
  MessageTooLong(String)
  InvalidChannel(String)
  UnknownError(String)
} derive(Show, Eq)

///|
/// Adapter lifecycle state
pub(all) enum AdapterState {
  Disconnected
  Connecting
  Connected
  Reconnecting
  Error(String)
} derive(Show, Eq)

///|
/// Base adapter configuration
pub(all) struct AdapterConfig {
  platform_name : String
  bot_user_id : String // For loop prevention
  api_token : String // Authentication token
  webhook_secret : String // For webhook validation
  retry_count : Int // Number of retries on failure
  retry_delay_ms : Int // Base delay between retries
} derive(Show, Eq)

///|
/// Create a new AdapterConfig
pub fn AdapterConfig::new(
  platform_name : String,
  bot_user_id : String,
  api_token : String,
) -> AdapterConfig {
  {
    platform_name,
    bot_user_id,
    api_token,
    webhook_secret: "",
    retry_count: 3,
    retry_delay_ms: 1000,
  }
}

///|
/// Check if message is from our bot (loop prevention)
pub fn is_self_message(config : AdapterConfig, sender_id : String) -> Bool {
  config.bot_user_id == sender_id
}

///|
/// Check if message should be ignored
pub fn should_ignore_message(
  config : AdapterConfig,
  message : NormalizedMessage,
) -> Bool {
  // Ignore messages from our bot
  if is_self_message(config, message.sender_id) {
    return true
  }
  // Ignore bot messages in general (can be configured)
  if message.is_bot {
    return true
  }
  false
}
