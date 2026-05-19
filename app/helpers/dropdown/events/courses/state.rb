# frozen_string_literal: true

#  Copyright (c) 2026, Hitobtio AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown::Events::Courses
  class State < ::Dropdown::Events::State
    private

    def state_item_course_canceled(label, _link)
      add_item_with_popover(label, template.render("events/popover_canceled_reason", entry: event))
    end
  end
end
