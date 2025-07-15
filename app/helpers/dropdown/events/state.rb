# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/HelperInstanceVariable

module Dropdown::Events
  class State < ::Dropdown::Base
    attr_reader :event, :template

    delegate :t, to: :template

    ID = "event-state-dropdown"

    EMAIL_OPTIONAL_TRANSITIONS = %w[
      application_open
      assignment_closed
      ready
    ]

    def initialize(template, event)
      @event = event
      @template = template
      super(template, current_state_label, :"exchange-alt")
      init_items
    end

    def to_s
      template.content_tag(:div, id: ID, class: "btn-group dropdown") do
        render_dropdown_button + render_items
      end
    end

    private

    def current_state_label
      t("activerecord.attributes.#{event.klass.model_name.i18n_key}.states.#{event.state}")
    end

    def init_items
      event.available_states.each do |state|
        link = template.state_group_event_path(template.params[:group_id], event, {state:})
        label = label_for(state)
        custom_method = :"state_item_#{event.klass.name.demodulize.downcase}_#{state}"
        if respond_to?(custom_method, true)
          send(custom_method, label, link)
        elsif EMAIL_OPTIONAL_TRANSITIONS.include?(state.to_s)
          add_item_with_popover(label, template.render("events/popover_emails_optional", state:, label:))
        else
          add_item(label, link, method: :put, "data-confirm": confirm_text_for(state))
        end
      end
    end

    def label_for(state)
      label_translation_default = t("#{i18n_base_key}.#{state}")
      if event.state_comes_before?(state, event.state)
        t(state, scope: "events.state_back_buttons", default: label_translation_default)
      else
        label_translation_default
      end
    end

    def confirm_text_for(state)
      key = "#{i18n_base_key}.#{state}_confirm_text"
      I18n.t(key) if I18n.exists?(key)
    end

    def state_item_course_canceled(label, _link)
      add_item_with_popover(label, template.render("events/popover_canceled_reason", entry: event))
    end

    def add_item_with_popover(label, content)
      add_item(label, "javascript:void(0)",
        "data-bs-toggle": "popover",
        "data-anchor": "##{ID}",
        "data-bs-placement": :bottom,
        "data-bs-content": content)
    end

    def i18n_base_key
      "events.state_buttons.#{event.klass.model_name.i18n_key}"
    end
  end
end

# rubocop:enable Rails/HelperInstanceVariable
