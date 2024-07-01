# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown::Events::Courses
  class State < ::Dropdown::Base

    attr_reader :course, :template

    delegate :t, to: :template

    def initialize(template, course)
      @course = course
      @template = template
      super(template, current_state_label, :'exchange-alt')
      init_items
    end

    private

    def current_state_label
      t("activerecord.attributes.event/course.states.#{course.state}")
    end

    def init_items
      course.available_states.each do |step|
        link = template.state_group_event_path(template.params[:group_id], course, { state: step })
        add_item(label_for_step(step), link, method: :put)
      end
    end

    def label_for_step(step)
      label_translation_default = t(".state_buttons.#{step}")
      if course.state_comes_before?(step, course.state)
        t(".state_back_buttons.#{step}",
          default: label_translation_default)
      else
        label_translation_default
      end
    end
  end
end
