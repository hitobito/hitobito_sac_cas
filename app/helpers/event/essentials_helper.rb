# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Event::EssentialsHelper
  def format_event_discipline_children(entry)
    format_event_essentials_children(entry.children)
  end

  def format_event_target_group_children(entry)
    format_event_essentials_children(entry.children)
  end

  def format_event_technical_requirement_children(entry)
    format_event_essentials_children(entry.children)
  end

  def format_event_trait_children(entry)
    format_event_essentials_children(entry.children)
  end

  def format_event_essentials_children(children)
    return ta(:no_entry) if children.blank?

    simple_list(children) do |val|
      item = assoc_link(val)
      if val.deleted_at
        item += " (#{t("global.deleted_at", date: format_column(:datetime, val.deleted_at))})"
      end
      item
    end
  end
end
