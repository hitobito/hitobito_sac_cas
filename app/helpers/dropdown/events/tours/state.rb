# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown::Events::Tours
  class State < ::Dropdown::Events::State
    private

    def state_item_tour_review(label, link)
      if event.approvals.exists?
        add_item_with_popover(label, template.render("events/tours/popover_review", entry: event))
      else
        add_default_item(label, link, :review)
      end
    end

    def state_item_tour_published(label, link)
      if event.state_comes_before?(event.state, :published)
        add_item_with_popover(label,
          template.render("events/tours/popover_published",
            entry: event))
      else
        add_item_with_popover(label,
          template.render("events/tours/popover_back_to_published",
            entry: event))
      end
    end

    def state_item_tour_ready(label, link)
      if event.state_comes_before?(event.state, :ready)
        add_item_with_popover(label, template.render("events/tours/popover_ready", entry: event))
      else
        add_item_with_popover(label,
          template.render("events/tours/popover_back_to_ready",
            entry: event))
      end
    end

    def state_item_tour_closed(label, link)
      add_item_with_popover(label, template.render("events/tours/popover_closed", entry: event))
    end

    def state_item_tour_canceled(label, link)
      add_item_with_popover(label, template.render("events/tours/popover_canceled", entry: event))
    end

    def state_item_tour_draft(label, link)
      add_item_with_popover(label,
        template.render("events/tours/popover_back_to_draft", entry: event))
    end

    def state_item_tour_approved(label, link)
      if event.state_comes_before?(event.state, :approved)
        add_default_item(label, link, :approved)
      else
        add_item_with_popover(label,
          template.render("events/tours/popover_back_to_approved",
            entry: event))
      end
    end
  end
end
