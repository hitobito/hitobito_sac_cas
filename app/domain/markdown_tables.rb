# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MarkdownTables
  require "redcarpet"

  SPACES = /(?:\s|&nbsp;)*/
  LINE_START = %r{(?:\A|<br>|<div[^>]*>)(?:</\w+>)*\s*}
  ROW = %r{\|(?:[^|<]*\|)+#{SPACES}(?:<br>|(?=</div>))}
  ROWS_IN_SEPARATE_BLOCKS = %r{\|#{SPACES}</div>\s*<div>\s*(?=\|)}
  MARKDOWN_TABLE_PATTERN = /#{LINE_START}\K(?:#{ROW})+/

  def initialize(html)
    @html = html
  end

  def to_html
    @html.gsub(ROWS_IN_SEPARATE_BLOCKS, "|<br>")
      .gsub(MARKDOWN_TABLE_PATTERN) { |rows| render_table(rows) || rows }
      .delete("\n").html_safe
  end

  private

  def render_table(rows)
    html = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
      .render(rows.gsub("<br>", "\n"))
    html if html.include?("<table>")
  end
end
