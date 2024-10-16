# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module RenderMarkdownTables
  require "redcarpet"

  MARKDOWN_TABLE_PATTERN = %r{(\|([^|<]*\|)+(?:<br>))+}

  def self.replace_markdown_tables(body)
    body.gsub(MARKDOWN_TABLE_PATTERN) do |markdown|
      Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true).render(markdown.gsub("<br>", "\n"))
    end.delete("\n").html_safe
  end
end
