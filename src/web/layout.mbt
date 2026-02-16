///|
fn app_style() -> String {
  [
    "* { box-sizing: border-box; }", "html, body { margin: 0; padding: 0; height: 100%; font-family: 'Space Grotesk', 'Noto Sans JP', sans-serif; background: #f8fafc; }",
    ".app { display: grid; grid-template-columns: 280px 1fr 360px; gap: 16px; height: 100%; padding: 16px; }",
    ".pane { background: #fff; border: 1px solid rgba(15, 23, 42, 0.08); border-radius: 12px; padding: 12px; min-height: 0; display: flex; flex-direction: column; }",
    ".pane-title { font-size: 14px; font-weight: 600; margin: 0 0 8px 0; color: #0f172a; }",
    ".ticket-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }",
    ".ticket-item { border: 1px solid transparent; background: #f1f5f9; padding: 10px 12px; border-radius: 8px; text-align: left; cursor: pointer; display: block; text-decoration: none; color: inherit; }",
    ".ticket-item.is-active { border-color: #2563eb; background: #eff6ff; }", ".chat-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 10px; overflow: auto; flex: 1; }",
    ".chat-item { background: #f8fafc; border-radius: 8px; padding: 8px 10px; }",
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
            @tmpx.strong_parts(parts([], [@tmpx.text(ticket.subject)])),
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
fn ticket_list(
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
fn message_item(message : @shared.Message) -> @tmpx.Node {
  @tmpx.li_parts(
    parts([@tmpx.class_("chat-item")], [
      @tmpx.div_parts(
        parts([@tmpx.class_("chat-item__meta")], [
          @tmpx.text(message.sender_id + " - " + message.origin.to_string()),
        ]),
      ),
      @tmpx.div_parts(
        parts([@tmpx.class_("chat-item__text")], [
          @tmpx.raw(escape_html_text(message.text)),
        ]),
      ),
    ]),
  )
}

///|
fn note_item(ticket_id : String, message : @shared.Message) -> @tmpx.Node {
  @tmpx.li_parts(
    parts([@tmpx.class_("chat-item")], [
      @tmpx.div_parts(
        parts([@tmpx.class_("chat-item__meta")], [
          @tmpx.text(message.sender_id + " - " + message.origin.to_string()),
        ]),
      ),
      @tmpx.div_parts(
        parts([@tmpx.class_("chat-item__text")], [
          @tmpx.raw(escape_html_text(message.text)),
        ]),
      ),
      @tmpx.form_parts(
        parts(
          [
            @tmpx.class_("note-edit-form"),
            @tmpx.mx_post(
              "/tickets/" + ticket_id + "/notes/" + message.message_id + "/edit",
            ),
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
    ]),
  )
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
      messages.map(fn(message) { note_item(ticket_id, message) }),
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
            @tmpx.text("Timeline - " + t.subject),
          ]),
        ),
        message_list(timeline),
        @tmpx.form_parts(
          parts(
            [
              @tmpx.class_("form"),
              @tmpx.id_("reply-form-" + t.ticket_id),
              @tmpx.attr("data-form-kind", "reply"),
              @tmpx.mx_post("/tickets/" + t.ticket_id + "/reply"),
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
        ),
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
            @tmpx.text("Notes - " + t.subject),
          ]),
        ),
        note_message_list(t.ticket_id, notes),
        @tmpx.form_parts(
          parts(
            [
              @tmpx.class_("form"),
              @tmpx.id_("note-form-" + t.ticket_id),
              @tmpx.attr("data-form-kind", "note"),
              @tmpx.mx_post("/tickets/" + t.ticket_id + "/notes"),
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
        ),
      ]
  }
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
                parts([@tmpx.id_("pane-left"), @tmpx.class_("pane")], [
                  @tmpx.h2_parts(
                    parts([@tmpx.class_("pane-title")], [@tmpx.text("Tickets")]),
                  ),
                  ticket_list(tickets, selected_id),
                ]),
              ),
              @tmpx.main_parts(
                parts(
                  [@tmpx.id_("pane-center"), @tmpx.class_("pane")],
                  center_nodes(selected_ticket, timeline, None),
                ),
              ),
              @tmpx.aside_parts(
                parts(
                  [@tmpx.id_("pane-right"), @tmpx.class_("pane")],
                  right_nodes(selected_ticket, notes, None),
                ),
              ),
            ]),
          ),
          @tmpx.unsafe_custom_element(
            "script",
            parts([@tmpx.src("/assets/mhx.js")], []),
          ),
          @tmpx.unsafe_custom_element(
            "script",
            parts([], [
              @tmpx.raw(
                "if (typeof mhx !== 'undefined') { mhx.init_mhx(); mhx.process(document.body); } document.addEventListener('keydown', function (event) { var target = event.target; if (!(target instanceof HTMLTextAreaElement)) { return; } if (target.getAttribute('data-shift-enter-send') !== 'true') { return; } if (event.key !== 'Enter' || !event.shiftKey) { return; } event.preventDefault(); var form = target.closest('form'); if (!form) { return; } if (typeof form.requestSubmit === 'function') { form.requestSubmit(); return; } form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true })); });",
              ),
            ]),
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
      [
        @tmpx.h2_parts(
          parts([@tmpx.class_("pane-title")], [@tmpx.text("Tickets")]),
        ),
        ticket_list(tickets, selected_id),
      ],
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
