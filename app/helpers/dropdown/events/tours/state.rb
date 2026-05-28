# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown::Events::Tours
  class State < ::Dropdown::Events::State
    private

    def state_item_tour_review(label, link)
      email_popover(label, "events/tours/popover_review")
    end

    def state_item_tour_published(label, link)
      if event.state_comes_before?(event.state, :published)
        email_popover(label, "events/tours/popover_published")
      else
        email_popover(label, "events/tours/popover_back_to_published")
      end
    end

    def state_item_tour_ready(label, link)
      if event.state_comes_before?(event.state, :ready)
        email_popover(label, "events/tours/popover_ready")
      else
        email_popover(label, "events/tours/popover_back_to_ready")
      end
    end

    def state_item_tour_closed(label, link)
      email_popover(label, "events/tours/popover_closed")
    end

    def state_item_tour_canceled(label, link)
      email_popover(label, "events/tours/popover_canceled")
    end

    def state_item_tour_draft(label, link)
      email_popover(label, "events/tours/popover_back_to_draft")
    end

    def state_item_tour_approved(label, link)
      if event.state_comes_before?(event.state, :approved)
        email_popover(label, "events/tours/popover_approved")
      else
        email_popover(label, "events/tours/popover_back_to_approved")
      end
    end

    def email_popover(label, partial)
      add_item_with_popover(label, template.render(partial, entry: event))
    end
  end
end
