# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown::Events::Courses
  class State < ::Dropdown::Base
    attr_reader :course, :template

    delegate :t, to: :template

    ID = "course-state-dropdown"

    def initialize(template, course)
      @course = course
      @template = template
      super(template, current_state_label, :"exchange-alt")
      init_items
    end

    def to_s
      template.content_tag(:div, id: ID, class: "btn-group dropdown") do
        render_dropdown_button +
          render_items
      end
    end

    private

    def current_state_label
      t("activerecord.attributes.event/course.states.#{course.state}")
    end

    def init_items
      course.available_states.each do |step|
        link = template.state_group_event_path(template.params[:group_id], course, {state: step})
        label = label_for_step(step)
        if respond_to?(:"state_item_#{step}", true)
          send(:"state_item_#{step}", label, link)
        else
          add_item(label, link, method: :put, "data-confirm": confirm_text_for_step(step))
        end
      end
    end

    def label_for_step(step)
      label_translation_default = t(".state_buttons.#{step}")
      if course.state_comes_before?(step, course.state)
        t(step, scope: ".state_back_buttons", default: label_translation_default)
      else
        label_translation_default
      end
    end

    def confirm_text_for_step(step)
      key = "events.actions_show_sac_cas.state_buttons.#{step}_confirm_text"
      I18n.t(key) if I18n.exists?(key)
    end

    def state_item_canceled(label, link)
      add_item(label, "javascript:void(0)",
        "data-bs-toggle": "popover",
        "data-anchor": "##{ID}",
        "data-bs-placement": :bottom,
        "data-bs-content": template.render("events/popover_canceled_reason", entry: course))
    end
  end
end
