///|
fn app_style() -> String {
  [
    "* { box-sizing: border-box; }", "html, body { margin: 0; padding: 0; height: 100%; font-family: 'Space Grotesk', 'Noto Sans JP', sans-serif; background: #f8fafc; }",
    ".app { display: grid; grid-template-columns: 280px 1fr 360px; gap: 16px; height: 100%; padding: 16px; }",
    ".pane { background: #fff; border: 1px solid rgba(15, 23, 42, 0.08); border-radius: 12px; padding: 12px; min-height: 0; display: flex; flex-direction: column; overflow: hidden; }",
    ".pane-title { font-size: 14px; font-weight: 600; margin: 0; color: #0f172a; }",
    ".pane-title-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }",
    ".ticket-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }",
    ".ticket-item { border: 1px solid transparent; background: #f1f5f9; padding: 10px 12px; border-radius: 8px; text-align: left; cursor: pointer; display: block; text-decoration: none; color: inherit; }",
    ".ticket-item.is-active { border-color: #2563eb; background: #eff6ff; }", ".chat-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; align-items: flex-start; gap: 10px; overflow-y: auto; overflow-x: hidden; flex: 1; min-height: 0; }",
    ".ticket-edit-panel { display: none; }", ".ticket-edit-panel.is-open { display: block; }",
    ".ticket-view-panel.is-hidden { display: none; }", ".ticket-edit-item { display: flex; gap: 8px; align-items: flex-start; }",
    ".ticket-edit-actions { display: flex; gap: 8px; margin: 8px 0; }", ".gear-btn { background: #e2e8f0; color: #0f172a; border: none; padding: 6px 8px; border-radius: 8px; cursor: pointer; font-size: 13px; }",
    ".chat-item { background: #f8fafc; border-radius: 8px; padding: 8px 10px; max-width: 88%; width: fit-content; flex: 0 0 auto; }",
    ".chat-item.chat-a { background: #eef2ff; margin-right: auto; border: 1px solid #c7d2fe; }",
    ".chat-item.console { background: #ecfeff; margin-left: auto; border: 1px solid #a5f3fc; }",
    ".chat-item.system { background: #fef3c7; margin-inline: auto; border: 1px solid #fde68a; }",
    ".chat-item__meta { font-size: 11px; color: #64748b; margin-bottom: 4px; }",
    ".chat-item__text { font-size: 13px; color: #0f172a; white-space: pre-wrap; }",
    ".note-edit-form { display: grid; gap: 6px; margin-top: 8px; }", ".note-actions { display: flex; gap: 6px; justify-content: flex-end; }",
    ".note-inline-input { min-height: 56px; }", ".form { margin-top: 10px; display: grid; gap: 8px; }",
    ".input { width: 100%; min-height: 80px; border-radius: 8px; border: 1px solid rgba(15, 23, 42, 0.16); padding: 8px; font-size: 13px; }",
    ".form-error { font-size: 12px; color: #b91c1c; background: #fef2f2; border: 1px solid #fecaca; border-radius: 8px; padding: 8px; }",
    ".btn { background: #2563eb; color: #fff; border: none; padding: 8px 12px; border-radius: 8px; cursor: pointer; font-size: 13px; }",
    ".btn.secondary { background: #0f172a; }", ".placeholder { color: #94a3b8; font-size: 13px; padding: 8px 0; }",
    "@media (max-width: 980px) { .app { grid-template-columns: 1fr; } }",
  ].join("\n")
}

///|
fn message_origin_class(origin : @shared.Origin) -> String {
  match origin {
    @shared.ChatA => "chat-a"
    @shared.Console => "console"
    @shared.System => "system"
  }
}

///|
fn sender_label(message : @shared.Message) -> String {
  if message.sender_name == "" {
    message.sender_id
  } else {
    message.sender_name
  }
}

///|
fn escape_html_text(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length())
  for c in text {
    if c == '&' {
      sb.write_string("&amp;")
    } else if c == '<' {
      sb.write_string("&lt;")
    } else if c == '>' {
      sb.write_string("&gt;")
    } else if c == '"' {
      sb.write_string("&quot;")
    } else if c == '\'' {
      sb.write_string("&#39;")
    } else if c.to_int() > 127 {
      sb.write_string("&#")
      sb.write_string(c.to_int().to_string())
      sb.write_string(";")
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
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
fn starts_with_at(text : String, start : Int, prefix : String) -> Bool {
  if start + prefix.length() > text.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if text[start + i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn is_url_terminator(ch : UInt16) -> Bool {
  ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t' || ch == '<' || ch == '>' ||
  ch == '"' || ch == '\''
}

///|
fn url_encode_component(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length() + 16)
  for c in text {
    let code = c.to_int()
    let is_alpha_num = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122)
    let is_safe = is_alpha_num || c == '-' || c == '_' || c == '.' || c == '~'
    if is_safe {
      sb.write_char(c)
    } else {
      sb.write_char('%')
      let hi = (code / 16) & 0xF
      let lo = code & 0xF
      sb.write_char(if hi < 10 { Int::unsafe_to_char(48 + hi) } else { Int::unsafe_to_char(65 + hi - 10) })
      sb.write_char(if lo < 10 { Int::unsafe_to_char(48 + lo) } else { Int::unsafe_to_char(65 + lo - 10) })
    }
  }
  sb.to_string()
}

///|
fn render_text_with_auto_links(text : String) -> String {
  let sb = StringBuilder::new(size_hint=text.length() + 48)
  let mut i = 0
  let mut plain_start = 0
  while i < text.length() {
    let is_http = starts_with_at(text, i, "http://")
    let is_https = starts_with_at(text, i, "https://")
    let is_proxy_rel = starts_with_at(text, i, "/attachments/proxy?url=")
    if is_http || is_https || is_proxy_rel {
      if plain_start < i {
        sb.write_string(escape_html_text(substring(text, plain_start, i)))
      }
      let mut j = i
      while j < text.length() && !is_url_terminator(text[j]) {
        j = j + 1
      }
      let url = substring(text, i, j)
      let proxy_href = if is_proxy_rel {
        url
      } else {
        "/attachments/proxy?url=" + url_encode_component(url)
      }
      let escaped = escape_html_text(url)
      sb.write_string("<a href=\"")
      sb.write_string(escape_html_text(proxy_href))
      sb.write_string("\" target=\"_blank\" rel=\"noopener noreferrer\">")
      sb.write_string(escaped)
      sb.write_string("</a>")
      i = j
      plain_start = j
    } else {
      i = i + 1
    }
  }
  if plain_start < text.length() {
    sb.write_string(escape_html_text(substring(text, plain_start, text.length())))
  }
  sb.to_string()
}

///|
fn file_line_url_start(line : String, start : Int) -> Int {
  for i in start..<line.length() {
    let is_http = starts_with_at(line, i, "http://")
    let is_https = starts_with_at(line, i, "https://")
    let is_proxy_rel = starts_with_at(line, i, "/attachments/proxy?url=")
    if (is_http || is_https || is_proxy_rel) &&
      (i == start || line[i - 1] == ' ') {
      return i
    }
  }
  -1
}

///|
fn render_file_line_with_filename_link(line : String) -> String? {
  let prefix = "[file] "
  if !starts_with_at(line, 0, prefix) {
    return None
  }
  let url_start = file_line_url_start(line, prefix.length())
  if url_start <= prefix.length() {
    return None
  }
  let file_name = substring(line, prefix.length(), url_start).trim().to_string()
  let raw_url = substring(line, url_start, line.length()).trim().to_string()
  if file_name == "" || raw_url == "" {
    return None
  }
  let href = if starts_with_at(raw_url, 0, "/attachments/proxy?url=") {
    raw_url
  } else {
    "/attachments/proxy?url=" + url_encode_component(raw_url)
  }
  Some(
    escape_html_text(prefix) + "<a href=\"" + escape_html_text(href) +
    "\" target=\"_blank\" rel=\"noopener noreferrer\">" +
    escape_html_text(file_name) + "</a>",
  )
}

///|
fn render_message_text_with_links(text : String) -> String {
  let lines = text.split("\n")
  let rendered : Array[String] = []
  for line in lines {
    let line_text = line.to_string()
    match render_file_line_with_filename_link(line_text) {
      Some(html) => rendered.push(html)
      None => rendered.push(render_text_with_auto_links(line_text))
    }
  }
  rendered.join("\n")
}

///|
fn subject_node(subject : String) -> @tmpx.Node {
  @tmpx.raw(escape_html_text(subject))
}

///|
fn titled_subject(prefix : String, subject : String) -> @tmpx.Node {
  @tmpx.fragment([@tmpx.text(prefix), subject_node(subject)])
}

///|
fn parts(
  attrs : Array[@tmpx.Attr],
  children : Array[@tmpx.Node],
) -> Array[@tmpx.Part] {
  let out : Array[@tmpx.Part] = []
  for attr in attrs {
    out.push(@tmpx.part_attr(attr))
  }
  for child in children {
    out.push(@tmpx.part_child(child))
  }
  out
}

///|
fn render_ticket_item(
  ticket : @shared.Ticket,
  selected_id : String?,
) -> @tmpx.Node {
  let is_active = match selected_id {
    Some(id) => id == ticket.ticket_id
    None => false
  }
  let classes : Array[String] = ["ticket-item"]
  if is_active {
    classes.push("is-active")
  }
  @tmpx.li_parts(
    parts([], [
      @tmpx.a_parts(
        parts(
          [
            @tmpx.class_list(classes),
            @tmpx.href("/tickets/" + ticket.ticket_id),
            @tmpx.mx_get("/partials/ticket/" + ticket.ticket_id),
            @tmpx.mx_target("#pane-center"),
            @tmpx.mx_swap(@tmpx.MxSwap::InnerHTML),
            @tmpx.attr("mx-push-url", "/tickets/" + ticket.ticket_id),
          ],
          [
            @tmpx.strong_parts(parts([], [subject_node(ticket.subject)])),
            @tmpx.p_parts(
              parts([], [
                @tmpx.text(
                  "#" + ticket.ticket_id + " - " + ticket.status.to_string(),
                ),
              ]),
            ),
          ],
        ),
      ),
    ]),
  )
}

///|
fn render_ticket_edit_item(ticket : @shared.Ticket) -> @tmpx.Node {
  @tmpx.li_parts(
    parts([@tmpx.class_("ticket-edit-item")], [
      @tmpx.unsafe_custom_element(
        "input",
        parts(
          [
            @tmpx.attr("type", "checkbox"),
            @tmpx.attr("name", "ticket_select"),
            @tmpx.attr("value", ticket.ticket_id),
          ],
          [],
        ),
      ),
      @tmpx.div_parts(
        parts([], [
          @tmpx.strong_parts(parts([], [subject_node(ticket.subject)])),
          @tmpx.p_parts(
            parts([], [
              @tmpx.text(
                "#" + ticket.ticket_id + " - " + ticket.status.to_string(),
              ),
            ]),
          ),
        ]),
      ),
    ]),
  )
}

///|
fn ticket_list_view(
  tickets : Array[@shared.Ticket],
  selected_id : String?,
) -> @tmpx.Node {
  @tmpx.ul_parts(
    parts(
      [@tmpx.class_("ticket-list")],
      tickets.map(fn(ticket) { render_ticket_item(ticket, selected_id) }),
    ),
  )
}

///|
fn ticket_list_edit(tickets : Array[@shared.Ticket]) -> @tmpx.Node {
  @tmpx.ul_parts(
    parts(
      [@tmpx.class_("ticket-list")],
      tickets.map(fn(ticket) { render_ticket_edit_item(ticket) }),
    ),
  )
}

///|
fn ticket_left_content(
  tickets : Array[@shared.Ticket],
  selected_id : String?,
) -> Array[@tmpx.Node] {
  let selected_id_segment = match selected_id {
    Some(id) => id
    None => "-"
  }
  [
    @tmpx.div_parts(
      parts([@tmpx.class_("pane-title-row")], [
        @tmpx.h2_parts(
          parts([@tmpx.class_("pane-title")], [@tmpx.text("Tickets")]),
        ),
        @tmpx.button_parts(
          parts(
            [
              @tmpx.class_("gear-btn"),
              @tmpx.attr("type", "button"),
              @tmpx.attr("onclick", "toggleTicketEditMode(true)"),
            ],
            [@tmpx.raw("&#9881;")],
          ),
        ),
      ]),
    ),
    @tmpx.div_parts(
      parts(
        [@tmpx.id_("ticket-view-panel"), @tmpx.class_("ticket-view-panel")],
        [ticket_list_view(tickets, selected_id)],
      ),
    ),
    @tmpx.form_parts(
      parts(
        [
          @tmpx.id_("ticket-edit-panel"),
          @tmpx.class_("ticket-edit-panel"),
          @tmpx.attr("method", "post"),
          @tmpx.attr("action", "/tickets/close"),
          @tmpx.mx_post("/tickets/close"),
          @tmpx.mx_trigger("submit prevent"),
          @tmpx.mx_target("#pane-left"),
          @tmpx.mx_swap(@tmpx.MxSwap::InnerHTML),
          @tmpx.attr("onsubmit", "return prepareTicketClose(this)"),
        ],
        [
          @tmpx.div_parts(
            parts([@tmpx.class_("ticket-edit-actions")], [
              @tmpx.button_parts(
                parts([@tmpx.class_("btn"), @tmpx.attr("type", "submit")], [
                  @tmpx.text("Confirm close"),
                ]),
              ),
              @tmpx.button_parts(
                parts(
                  [
                    @tmpx.class_("btn secondary"),
                    @tmpx.attr("type", "button"),
                    @tmpx.attr("onclick", "toggleTicketEditMode(false)"),
                  ],
                  [@tmpx.text("Cancel")],
                ),
              ),
            ]),
          ),
          @tmpx.unsafe_custom_element(
            "input",
            parts(
              [
                @tmpx.attr("type", "hidden"),
                @tmpx.attr("name", "ticket_ids_csv"),
                @tmpx.attr("value", ""),
              ],
              [],
            ),
          ),
          @tmpx.unsafe_custom_element(
            "input",
            parts(
              [
                @tmpx.attr("type", "hidden"),
                @tmpx.attr("name", "selected_ticket_id"),
                @tmpx.attr("value", selected_id_segment),
              ],
              [],
            ),
          ),
          ticket_list_edit(tickets),
        ],
      ),
    ),
  ]
}

///|
fn message_item(message : @shared.Message) -> @tmpx.Node {
  let classes = ["chat-item", message_origin_class(message.origin)]
  @tmpx.li_parts(
    parts([@tmpx.class_list(classes)], [
      @tmpx.div_parts(
        parts([@tmpx.class_("chat-item__meta")], [
          @tmpx.text(sender_label(message) + " - " + message.origin.to_string()),
        ]),
      ),
      @tmpx.div_parts(
        parts([@tmpx.class_("chat-item__text")], [
          @tmpx.raw(render_message_text_with_links(message.text)),
        ]),
      ),
    ]),
  )
}

///|
fn note_item(
  ticket_id : String,
  message : @shared.Message,
  is_closed_ticket : Bool,
) -> @tmpx.Node {
  let classes = ["chat-item", message_origin_class(message.origin)]
  let nodes : Array[@tmpx.Node] = [
    @tmpx.div_parts(
      parts([@tmpx.class_("chat-item__meta")], [
        @tmpx.text(sender_label(message) + " - " + message.origin.to_string()),
      ]),
    ),
    @tmpx.div_parts(
      parts([@tmpx.class_("chat-item__text")], [
        @tmpx.raw(render_message_text_with_links(message.text)),
      ]),
    ),
  ]
  if !is_closed_ticket {
    nodes.push(
      @tmpx.form_parts(
        parts(
          [
            @tmpx.class_("note-edit-form"),
            @tmpx.attr("method", "post"),
            @tmpx.attr(
              "action",
              "/tickets/" + ticket_id + "/notes/" + message.message_id + "/edit",
            ),
            @tmpx.mx_post(
              "/tickets/" + ticket_id + "/notes/" + message.message_id + "/edit",
            ),
            @tmpx.mx_trigger("submit prevent"),
            @tmpx.mx_target("#pane-right"),
            @tmpx.mx_swap(@tmpx.MxSwap::InnerHTML),
          ],
          [
            @tmpx.textarea_parts(
              parts(
                [
                  @tmpx.class_("input note-inline-input"),
                  @tmpx.attr("name", "note_text"),
                ],
                [@tmpx.raw(escape_html_text(message.text))],
              ),
            ),
            @tmpx.unsafe_custom_element(
              "input",
              parts(
                [
                  @tmpx.attr("type", "hidden"),
                  @tmpx.attr("name", "intent"),
                  @tmpx.attr("value", "note"),
                ],
                [],
              ),
            ),
            @tmpx.div_parts(
              parts([@tmpx.class_("note-actions")], [
                @tmpx.button_parts(
                  parts(
                    [
                      @tmpx.class_("btn secondary"),
                      @tmpx.attr("type", "submit"),
                    ],
                    [@tmpx.text("Save note")],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    )
    nodes.push(
      @tmpx.form_parts(
        parts(
          [
            @tmpx.class_("note-actions"),
            @tmpx.attr("method", "post"),
            @tmpx.attr(
              "action",
              "/tickets/" +
              ticket_id +
              "/notes/" +
              message.message_id +
              "/delete",
            ),
          ],
          [
            @tmpx.unsafe_custom_element(
              "input",
              parts(
                [
                  @tmpx.attr("type", "hidden"),
                  @tmpx.attr("name", "intent"),
                  @tmpx.attr("value", "note"),
                ],
                [],
              ),
            ),
            @tmpx.button_parts(
              parts([@tmpx.class_("btn"), @tmpx.attr("type", "submit")], [
                @tmpx.text("Delete note"),
              ]),
            ),
          ],
        ),
      ),
    )
  }
  @tmpx.li_parts(parts([@tmpx.class_list(classes)], nodes))
}

///|
fn message_list(messages : Array[@shared.Message]) -> @tmpx.Node {
  if messages.is_empty() {
    return @tmpx.div_parts(
      parts([@tmpx.class_("placeholder")], [@tmpx.text("No messages yet.")]),
    )
  }
  @tmpx.ul_parts(parts([@tmpx.class_("chat-list")], messages.map(message_item)))
}

///|
fn note_message_list(
  ticket_id : String,
  is_closed_ticket : Bool,
  messages : Array[@shared.Message],
) -> @tmpx.Node {
  if messages.is_empty() {
    return @tmpx.div_parts(
      parts([@tmpx.class_("placeholder")], [@tmpx.text("No messages yet.")]),
    )
  }
  @tmpx.ul_parts(
    parts(
      [@tmpx.class_("chat-list")],
      messages.map(fn(message) {
        note_item(ticket_id, message, is_closed_ticket)
      }),
    ),
  )
}

///|
fn center_nodes(
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
  error : String?,
) -> Array[@tmpx.Node] {
  match ticket {
    None =>
      [
        @tmpx.h2_parts(
          parts([@tmpx.class_("pane-title")], [@tmpx.text("Timeline")]),
        ),
        @tmpx.div_parts(
          parts([@tmpx.class_("placeholder")], [
            @tmpx.text("Select a ticket to view the conversation."),
          ]),
        ),
      ]
    Some(t) =>
      [
        @tmpx.h2_parts(
          parts([@tmpx.class_("pane-title")], [
            titled_subject("Timeline - ", t.subject),
          ]),
        ),
        message_list(timeline),
        if t.status == @shared.Closed {
          @tmpx.div_parts(
            parts([@tmpx.class_("placeholder")], [
              @tmpx.text("This ticket is closed. Send reply is disabled."),
            ]),
          )
        } else {
          @tmpx.form_parts(
            parts(
              [
                @tmpx.class_("form"),
                @tmpx.id_("reply-form-" + t.ticket_id),
                @tmpx.attr("data-form-kind", "reply"),
                @tmpx.attr("method", "post"),
                @tmpx.attr("action", "/tickets/" + t.ticket_id + "/reply"),
                @tmpx.mx_post("/tickets/" + t.ticket_id + "/reply"),
                @tmpx.mx_trigger("submit prevent"),
                @tmpx.mx_target("#pane-center"),
                @tmpx.mx_swap(@tmpx.MxSwap::InnerHTML),
              ],
              [
                match error {
                  Some(msg) =>
                    @tmpx.div_parts(
                      parts([@tmpx.class_("form-error")], [@tmpx.text(msg)]),
                    )
                  None => @tmpx.fragment([])
                },
                @tmpx.textarea_parts(
                  parts(
                    [
                      @tmpx.class_("input"),
                      @tmpx.attr("name", "reply_text"),
                      @tmpx.attr("data-shift-enter-send", "true"),
                      @tmpx.attr("data-submit-role", "reply"),
                      @tmpx.attr("placeholder", "Write a public reply..."),
                    ],
                    [],
                  ),
                ),
                @tmpx.unsafe_custom_element(
                  "input",
                  parts(
                    [
                      @tmpx.attr("type", "hidden"),
                      @tmpx.attr("name", "intent"),
                      @tmpx.attr("value", "reply"),
                    ],
                    [],
                  ),
                ),
                @tmpx.button_parts(
                  parts(
                    [
                      @tmpx.class_("btn"),
                      @tmpx.attr("type", "submit"),
                      @tmpx.attr("data-submit-role", "reply"),
                    ],
                    [@tmpx.text("Send reply")],
                  ),
                ),
              ],
            ),
          )
        },
      ]
  }
}

///|
fn right_nodes(
  ticket : @shared.Ticket?,
  notes : Array[@shared.Message],
  error : String?,
) -> Array[@tmpx.Node] {
  match ticket {
    None =>
      [
        @tmpx.h2_parts(
          parts([@tmpx.class_("pane-title")], [@tmpx.text("Notes")]),
        ),
        @tmpx.div_parts(
          parts([@tmpx.class_("placeholder")], [
            @tmpx.text("Select a ticket to write internal notes."),
          ]),
        ),
      ]
    Some(t) =>
      [
        @tmpx.h2_parts(
          parts([@tmpx.class_("pane-title")], [
            titled_subject("Notes - ", t.subject),
          ]),
        ),
        note_message_list(t.ticket_id, t.status == @shared.Closed, notes),
        if t.status == @shared.Closed {
          @tmpx.div_parts(
            parts([@tmpx.class_("placeholder")], [
              @tmpx.text("This ticket is closed. Add note is disabled."),
            ]),
          )
        } else {
          @tmpx.form_parts(
            parts(
              [
                @tmpx.class_("form"),
                @tmpx.id_("note-form-" + t.ticket_id),
                @tmpx.attr("data-form-kind", "note"),
                @tmpx.attr("method", "post"),
                @tmpx.attr("action", "/tickets/" + t.ticket_id + "/notes"),
                @tmpx.mx_post("/tickets/" + t.ticket_id + "/notes"),
                @tmpx.mx_trigger("submit prevent"),
                @tmpx.mx_target("#pane-right"),
                @tmpx.mx_swap(@tmpx.MxSwap::InnerHTML),
              ],
              [
                match error {
                  Some(msg) =>
                    @tmpx.div_parts(
                      parts([@tmpx.class_("form-error")], [@tmpx.text(msg)]),
                    )
                  None => @tmpx.fragment([])
                },
                @tmpx.textarea_parts(
                  parts(
                    [
                      @tmpx.class_("input"),
                      @tmpx.attr("name", "note_text"),
                      @tmpx.attr("data-shift-enter-send", "true"),
                      @tmpx.attr("data-submit-role", "note"),
                      @tmpx.attr("placeholder", "Write an internal note..."),
                    ],
                    [],
                  ),
                ),
                @tmpx.unsafe_custom_element(
                  "input",
                  parts(
                    [
                      @tmpx.attr("type", "hidden"),
                      @tmpx.attr("name", "intent"),
                      @tmpx.attr("value", "note"),
                    ],
                    [],
                  ),
                ),
                @tmpx.button_parts(
                  parts(
                    [
                      @tmpx.class_("btn secondary"),
                      @tmpx.attr("type", "submit"),
                      @tmpx.attr("data-submit-role", "note"),
                    ],
                    [@tmpx.text("Add note")],
                  ),
                ),
              ],
            ),
          )
        },
      ]
  }
}

///|
fn app_script() -> String {
  [
    "if (typeof mhx !== 'undefined') {", "  mhx.init_mhx();", "  mhx.process(document.body);",
    "}", "function selectedTicketId() {", "  var path = window.location.pathname || '/';",
    "  var m = path.match(/^\\/tickets\\/([^\\/]+)$/);", "  return m ? m[1] : '-';",
    "}", "window.toggleTicketEditMode = function (enabled) {", "  var view = document.getElementById('ticket-view-panel');",
    "  var edit = document.getElementById('ticket-edit-panel');", "  if (!view || !edit) { return; }",
    "  if (enabled) {", "    view.classList.add('is-hidden');", "    edit.classList.add('is-open');",
    "  } else {", "    view.classList.remove('is-hidden');", "    edit.classList.remove('is-open');",
    "  }", "};", "window.prepareTicketClose = function (form) {", "  var checks = form.querySelectorAll('input[name=\"ticket_select\"]:checked');",
    "  var ids = [];", "  for (var i = 0; i < checks.length; i += 1) {", "    ids.push(checks[i].value);",
    "  }", "  var csv = form.querySelector('input[name=\"ticket_ids_csv\"]');", "  if (csv) { csv.value = ids.join(','); }",
    "  var selected = form.querySelector('input[name=\"selected_ticket_id\"]');",
    "  if (selected) { selected.value = selectedTicketId(); }", "  return true;",
    "};", "document.addEventListener('keydown', function (event) {", "  var target = event.target;",
    "  if (!(target instanceof HTMLTextAreaElement)) { return; }", "  if (target.getAttribute('data-shift-enter-send') !== 'true') { return; }",
    "  if (event.key !== 'Enter' || !event.shiftKey) { return; }", "  event.preventDefault();",
    "  var form = target.closest('form');", "  if (!form) { return; }", "  if (typeof form.requestSubmit === 'function') {",
    "    form.requestSubmit();", "    return;", "  }", "  form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));",
    "});", "(function () {", "  if (typeof EventSource === 'undefined') { return; }",
    "  var eventSource = new EventSource('/events');", "  var refresh = function () {",
    "    var ticketId = selectedTicketId();", "    var left = document.getElementById('pane-left');",
    "    if (left) {", "      left.setAttribute('mx-get', '/partials/tickets/' + ticketId);",
    "      left.dispatchEvent(new Event('input', { bubbles: true }));", "    }",
    "    var center = document.getElementById('pane-center');", "    if (center) {",
    "      center.setAttribute('mx-get', '/partials/ticket/' + ticketId + '/center');",
    "      center.dispatchEvent(new Event('input', { bubbles: true }));", "    }",
    "    var right = document.getElementById('pane-right');", "    if (right) {",
    "      right.setAttribute('mx-get', '/partials/ticket/' + ticketId + '/right');",
    "      right.dispatchEvent(new Event('input', { bubbles: true }));", "    }",
    "  };", "  eventSource.addEventListener('ticket-updated', refresh);", "  eventSource.addEventListener('message', refresh);",
    "})();",
  ].join("\n")
}

///|
pub fn render_index(
  tickets : Array[@shared.Ticket],
  selected_ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
  notes : Array[@shared.Message],
) -> String {
  let selected_id = match selected_ticket {
    Some(t) => Some(t.ticket_id)
    None => None
  }
  let selected_id_segment = match selected_id {
    Some(id) => id
    None => "-"
  }
  let left_attrs : Array[@tmpx.Attr] = [
    @tmpx.id_("pane-left"),
    @tmpx.class_("pane"),
    @tmpx.mx_get("/partials/tickets/" + selected_id_segment),
    @tmpx.mx_trigger("input[target.id=='pane-left']"),
    @tmpx.mx_swap(@tmpx.MxSwap::InnerHTML),
  ]
  let center_attrs : Array[@tmpx.Attr] = [
    @tmpx.id_("pane-center"),
    @tmpx.class_("pane"),
  ]
  let right_attrs : Array[@tmpx.Attr] = [
    @tmpx.id_("pane-right"),
    @tmpx.class_("pane"),
  ]
  match selected_ticket {
    Some(t) => {
      center_attrs.push(
        @tmpx.mx_get("/partials/ticket/" + t.ticket_id + "/center"),
      )
      center_attrs.push(@tmpx.mx_trigger("input[target.id=='pane-center']"))
      center_attrs.push(@tmpx.mx_swap(@tmpx.MxSwap::InnerHTML))
      right_attrs.push(
        @tmpx.mx_get("/partials/ticket/" + t.ticket_id + "/right"),
      )
      right_attrs.push(@tmpx.mx_trigger("input[target.id=='pane-right']"))
      right_attrs.push(@tmpx.mx_swap(@tmpx.MxSwap::InnerHTML))
    }
    None => ()
  }
  let page = @tmpx.html_parts(
    parts([@tmpx.attr("lang", "ja")], [
      @tmpx.head_parts(
        parts([], [
          @tmpx.meta_attrs([@tmpx.attr("charset", "utf-8")]),
          @tmpx.title_parts(parts([], [@tmpx.text("it-support-app")])),
          @tmpx.unsafe_custom_element(
            "style",
            parts([], [@tmpx.raw(app_style())]),
          ),
        ]),
      ),
      @tmpx.body_parts(
        parts([], [
          @tmpx.div_parts(
            parts([@tmpx.class_("app")], [
              @tmpx.aside_parts(
                parts(left_attrs, ticket_left_content(tickets, selected_id)),
              ),
              @tmpx.main_parts(
                parts(
                  center_attrs,
                  center_nodes(selected_ticket, timeline, None),
                ),
              ),
              @tmpx.aside_parts(
                parts(right_attrs, right_nodes(selected_ticket, notes, None)),
              ),
            ]),
          ),
          @tmpx.unsafe_custom_element(
            "script",
            parts([@tmpx.src("/assets/mhx.js")], []),
          ),
          @tmpx.unsafe_custom_element(
            "script",
            parts([], [@tmpx.raw(app_script())]),
          ),
        ]),
      ),
    ]),
  )
  "<!DOCTYPE html>" + @tmpx.render(page)
}

///|
pub fn render_ticket_partial(
  tickets : Array[@shared.Ticket],
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
  notes : Array[@shared.Message],
) -> String {
  let selected_id = match ticket {
    Some(t) => Some(t.ticket_id)
    None => None
  }
  let left_oob = @tmpx.aside_parts(
    parts(
      [
        @tmpx.id_("pane-left"),
        @tmpx.class_("pane"),
        @tmpx.attr("mx-swap-oob", @tmpx.MxSwap::InnerHTML.to_string()),
      ],
      ticket_left_content(tickets, selected_id),
    ),
  )
  let right_oob = @tmpx.div_parts(
    parts(
      [
        @tmpx.id_("pane-right"),
        @tmpx.class_("pane"),
        @tmpx.attr("mx-swap-oob", @tmpx.MxSwap::InnerHTML.to_string()),
      ],
      right_nodes(ticket, notes, None),
    ),
  )
  let nodes = center_nodes(ticket, timeline, None)
  nodes.push(right_oob)
  nodes.push(left_oob)
  @tmpx.render(@tmpx.fragment(nodes))
}

///|
pub fn render_center_partial(
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
  error : String?,
) -> String {
  @tmpx.render(@tmpx.fragment(center_nodes(ticket, timeline, error)))
}

///|
pub fn render_right_partial(
  ticket : @shared.Ticket?,
  notes : Array[@shared.Message],
  error : String?,
) -> String {
  @tmpx.render(@tmpx.fragment(right_nodes(ticket, notes, error)))
}

///|
pub fn render_left_partial(
  tickets : Array[@shared.Ticket],
  selected_id : String?,
) -> String {
  @tmpx.render(@tmpx.fragment(ticket_left_content(tickets, selected_id)))
}
