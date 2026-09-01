# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# One of the agenda pages' inline icons, rendered as an SVG - sized/
# coloured via CSS (currentColor + the .agenda-icon class) exactly like
# the prototype's Lucide icons, never FontAwesome, which the agenda pages
# don't load.
class AgendaIcon
  include ActionView::Helpers::TagHelper

  # Icon paths copied verbatim from the Lucide icon set
  # https://lucide.dev ISC licensed
  AGENDA_ICONS = {
    activity: '<path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0' \
      'L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2" />',
    alert_triangle: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 ' \
      '0 0 1.73-3" /><path d="M12 9v4" /><path d="M12 17h.01" />',
    arrow_left: '<path d="m12 19-7-7 7-7" /><path d="M19 12H5" />',
    calendar: '<path d="M8 2v3" /><path d="M16 2v3" />' \
      '<rect x="3" y="3" width="18" height="18" rx="2" /><path d="M3 9h18" />',
    calendar_check: '<path d="M8 2v3" /><path d="M16 2v3" />' \
      '<rect x="3" y="3" width="18" height="18" rx="2" /><path d="M3 9h18" />' \
      '<path d="m9 15 2 2 4-4" />',
    chevron_down: '<path d="m6 9 6 6 6-6" />',
    clock: '<circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" />',
    gauge: '<path d="m12 14 4-4" /><path d="M3.34 19a10 10 0 1 1 17.32 0" />',
    link: '<path d="M15 3h6v6"></path>' \
       '<path d="M10 14 21 3"></path>' \
       '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>',
    mail: '<path d="m22 7-8.991 5.727a2 2 0 0 1-2.009 0L2 7" />' \
      '<rect x="2" y="4" width="20" height="16" rx="2" />',
    map_pin: '<path d="M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 ' \
      '20.193 4 14.993 4 10a8 8 0 0 1 16 0" /><circle cx="12" cy="10" r="3" />',
    mountain: '<path d="m8 3 4 8 5-5 5 15H2L8 3z" />',
    phone: '<path d="M13.832 16.568a1 1 0 0 0 1.213-.303l.355-.465A2 2 0 0 1 17 15h3a2 2 0 0 ' \
      "1 2 2v3a2 2 0 0 1-2 2A18 18 0 0 1 2 4a2 2 0 0 1 2-2h3a2 2 0 0 1 2 2v3a2 2 0 0 1-.8 " \
      '1.6l-.468.351a1 1 0 0 0-.292 1.233 14 14 0 0 0 6.392 6.384" />',
    rotate_ccw: '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8" />' \
      '<path d="M3 3v5h5" />',
    search: '<path d="m21 21-4.34-4.34" /><circle cx="11" cy="11" r="8" />',
    search_x: '<path d="m13.5 8.5-5 5" /><path d="m8.5 8.5 5 5" />' \
      '<circle cx="11" cy="11" r="8" /><path d="m21 21-4.3-4.3" />',
    tag: '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 ' \
      '.586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z" />' \
      '<circle cx="7.5" cy="7.5" r=".5" fill="currentColor" />',
    trending_up: '<path d="M16 7h6v6" /><path d="m22 7-8.5 8.5-5-5L2 17" />',
    user: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" />' \
      '<circle cx="12" cy="7" r="4" />',
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />' \
      '<path d="M16 3.128a4 4 0 0 1 0 7.744" />' \
      '<path d="M22 21v-2a4 4 0 0 0-3-3.87" />' \
      '<circle cx="9" cy="7" r="4" />',
    wallet: '<path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 ' \
      '0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1" /><path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 ' \
      '1-1v-4" />',
    x: '<path d="M18 6 6 18" /><path d="m6 6 12 12" />'
  }.freeze

  def initialize(name)
    @name = name
  end

  # Renders as an inline SVG, sized/coloured via CSS (currentColor + the
  # .agenda-icon class). Accepts `class:` as a plain **attributes entry,
  # not a named `class:` parameter - that's a reserved word, so it can be
  # a keyword argument's name but never a bare local variable read back
  # out of one inside the method body.
  def to_svg(**attributes)
    content_tag(:svg,
      AGENDA_ICONS.fetch(@name.to_sym).html_safe,
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 2,
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      class: ["agenda-icon", attributes[:class]].compact.join(" "),
      "aria-hidden": "true",
      focusable: "false")
  end
end
