///|
fn app_style() -> String {
  [
    "* { box-sizing: border-box; }",
    "html, body { margin: 0; padding: 0; height: 100%; font-family: 'Space Grotesk', 'Noto Sans JP', sans-serif; background: #f8fafc; }",
    ".app { display: grid; grid-template-columns: 280px 1fr 360px; gap: 16px; height: 100%; padding: 16px; }",
    ".pane { background: #fff; border: 1px solid rgba(15, 23, 42, 0.08); border-radius: 12px; padding: 12px; min-height: 0; display: flex; flex-direction: column; }",
    ".pane-title { font-size: 14px; font-weight: 600; margin: 0 0 8px 0; color: #0f172a; }",
    ".ticket-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 8px; }",
    ".ticket-item { border: 1px solid transparent; background: #f1f5f9; padding: 10px 12px; border-radius: 8px; text-align: left; cursor: pointer; }",
    ".ticket-item.is-active { border-color: #2563eb; background: #eff6ff; }",
    ".chat-list { list-style: none; margin: 0; padding: 0; display: grid; gap: 10px; overflow: auto; flex: 1; }",
    ".chat-item { background: #f8fafc; border-radius: 8px; padding: 8px 10px; }",
    ".chat-item__meta { font-size: 11px; color: #64748b; margin-bottom: 4px; }",
    ".chat-item__text { font-size: 13px; color: #0f172a; white-space: pre-wrap; }",
    ".form { margin-top: 10px; display: grid; gap: 8px; }",
    ".input { width: 100%; min-height: 80px; border-radius: 8px; border: 1px solid rgba(15, 23, 42, 0.16); padding: 8px; font-size: 13px; }",
    ".btn { background: #2563eb; color: #fff; border: none; padding: 8px 12px; border-radius: 8px; cursor: pointer; font-size: 13px; }",
    ".btn.secondary { background: #0f172a; }",
    ".placeholder { color: #94a3b8; font-size: 13px; padding: 8px 0; }",
    "@media (max-width: 980px) { .app { grid-template-columns: 1fr; } }",
  ].join("\n")
}

///|
fn render_ticket_item(ticket : @shared.Ticket, selected_id : String?) -> @tmpx.Node {
  let is_active = match selected_id {
    Some(id) => id == ticket.ticket_id
    None => false
  }
  let classes : Array[String] = ["ticket-item"]
  if is_active {
    classes.push("is-active")
  }
  @tmpx.li([], [
    @tmpx.button([
      @tmpx.class_list(classes),
      @tmpx.type_("button"),
      @tmpx.hx_get("/partials/ticket/" + ticket.ticket_id),
      @tmpx.hx_target("#pane-center"),
      @tmpx.hx_swap(@tmpx.HxSwap::InnerHTML),
      @tmpx.hx_push_url(true),
    ], [
      @tmpx.strong([], [@tmpx.text(ticket.subject)]),
      @tmpx.p([], [@tmpx.text("#" + ticket.ticket_id + " - " + ticket.status.to_string())]),
    ]),
  ])
}

///|
fn ticket_list(tickets : Array[@shared.Ticket], selected_id : String?) -> @tmpx.Node {
  @tmpx.ul([
    @tmpx.class_("ticket-list"),
  ], tickets.map(fn(ticket) { render_ticket_item(ticket, selected_id) }))
}

///|
fn message_item(message : @shared.Message) -> @tmpx.Node {
  @tmpx.li([
    @tmpx.class_("chat-item"),
  ], [
    @tmpx.div([
      @tmpx.class_("chat-item__meta"),
    ], [
      @tmpx.text(message.sender_id + " - " + message.origin.to_string()),
    ]),
    @tmpx.div([
      @tmpx.class_("chat-item__text"),
    ], [
      @tmpx.text(message.text),
    ]),
  ])
}

///|
fn message_list(messages : Array[@shared.Message]) -> @tmpx.Node {
  if messages.is_empty() {
    return @tmpx.div([
      @tmpx.class_("placeholder"),
    ], [@tmpx.text("No messages yet.")])
  }
  @tmpx.ul([
    @tmpx.class_("chat-list"),
  ], messages.map(message_item))
}

///|
fn center_nodes(
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
) -> Array[@tmpx.Node] {
  match ticket {
    None => [
      @tmpx.h2([
        @tmpx.class_("pane-title"),
      ], [@tmpx.text("Timeline")]),
      @tmpx.div([
        @tmpx.class_("placeholder"),
      ], [@tmpx.text("Select a ticket to view the conversation.")]),
    ]
    Some(t) => [
      @tmpx.h2([
        @tmpx.class_("pane-title"),
      ], [@tmpx.text("Timeline - " + t.subject)]),
      message_list(timeline),
      @tmpx.form([
        @tmpx.class_("form"),
        @tmpx.method_("post"),
        @tmpx.hx_post("/tickets/" + t.ticket_id + "/reply"),
        @tmpx.hx_target("#pane-center"),
        @tmpx.hx_swap(@tmpx.HxSwap::InnerHTML),
      ], [
        @tmpx.textarea([
          @tmpx.class_("input"),
          @tmpx.name_("text"),
          @tmpx.placeholder("Write a public reply..."),
        ], []),
        @tmpx.button([
          @tmpx.class_("btn"),
          @tmpx.type_("submit"),
        ], [@tmpx.text("Send reply")]),
      ]),
    ]
  }
}

///|
fn right_nodes(
  ticket : @shared.Ticket?,
  notes : Array[@shared.Message],
) -> Array[@tmpx.Node] {
  match ticket {
    None => [
      @tmpx.h2([
        @tmpx.class_("pane-title"),
      ], [@tmpx.text("Notes")]),
      @tmpx.div([
        @tmpx.class_("placeholder"),
      ], [@tmpx.text("Select a ticket to write internal notes.")]),
    ]
    Some(t) => [
      @tmpx.h2([
        @tmpx.class_("pane-title"),
      ], [@tmpx.text("Notes - " + t.subject)]),
      message_list(notes),
      @tmpx.form([
        @tmpx.class_("form"),
        @tmpx.method_("post"),
        @tmpx.hx_post("/tickets/" + t.ticket_id + "/notes"),
        @tmpx.hx_target("#pane-right"),
        @tmpx.hx_swap(@tmpx.HxSwap::InnerHTML),
      ], [
        @tmpx.textarea([
          @tmpx.class_("input"),
          @tmpx.name_("text"),
          @tmpx.placeholder("Write an internal note..."),
        ], []),
        @tmpx.button([
          @tmpx.class_("btn secondary"),
          @tmpx.type_("submit"),
        ], [@tmpx.text("Add note")]),
      ]),
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
  let page = @tmpx.html_([
    @tmpx.lang_attr("ja"),
  ], [
    @tmpx.head([], [
      @tmpx.meta([
        @tmpx.charset("utf-8"),
      ]),
      @tmpx.title([], [@tmpx.text("it-support-app")]),
      @tmpx.style_([], [@tmpx.raw_html(app_style())]),
    ]),
    @tmpx.body([], [
      @tmpx.div([
        @tmpx.class_("app"),
      ], [
        @tmpx.aside([
          @tmpx.id_("pane-left"),
          @tmpx.class_("pane"),
        ], [
          @tmpx.h2([
            @tmpx.class_("pane-title"),
          ], [@tmpx.text("Tickets")]),
          ticket_list(tickets, selected_id),
        ]),
        @tmpx.main_([
          @tmpx.id_("pane-center"),
          @tmpx.class_("pane"),
        ], center_nodes(selected_ticket, timeline)),
        @tmpx.aside([
          @tmpx.id_("pane-right"),
          @tmpx.class_("pane"),
        ], right_nodes(selected_ticket, notes)),
      ]),
      @tmpx.script([
        @tmpx.src("/assets/htmx.js"),
      ], []),
    ]),
  ])
  "<!DOCTYPE html>" + @tmpx.render(page)
}

///|
pub fn render_ticket_partial(
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
  notes : Array[@shared.Message],
) -> String {
  let right_oob = @tmpx.div([
    @tmpx.id_("pane-right"),
    @tmpx.class_("pane"),
    @tmpx.hx_swap_oob(style=@tmpx.HxSwap::InnerHTML),
  ], right_nodes(ticket, notes))
  let nodes = center_nodes(ticket, timeline)
  nodes.push(right_oob)
  @tmpx.render_nodes(nodes)
}

///|
pub fn render_center_partial(
  ticket : @shared.Ticket?,
  timeline : Array[@shared.Message],
) -> String {
  @tmpx.render_nodes(center_nodes(ticket, timeline))
}

///|
pub fn render_right_partial(
  ticket : @shared.Ticket?,
  notes : Array[@shared.Message],
) -> String {
  @tmpx.render_nodes(right_nodes(ticket, notes))
}
