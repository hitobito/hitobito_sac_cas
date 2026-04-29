# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Events::Filter::AgendaList < Filter::List
  self.item_class = Event
  self.filter_chain_class = Events::Filter::Chain

  private

  def filtered_scope
    super.joins(:dates)
      .where("events.type IS DISTINCT FROM ? OR events.state IN (?)",
        "Event::Tour",
        %i[published ready closed canceled])
  end

  def accessible_scope
    Event.joins(:groups)
      .where(groups: {id: params[:group_id]})
      .where(globally_visible: true)
  end

  def init_filter_chain(filters)
    filter_chain_class.new(event_type, filters)
  end

  def event_type
    nil
  end
end
