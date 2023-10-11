# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class StepsComponent < ApplicationComponent
  renders_many :headers, 'HeaderComponent'
  renders_many :steps, 'StepComponent'

  attr_accessor :step, :partials

  def initialize(partials: [], step:, form:)
    @partials = partials
    @step = step
    @form = form
  end

  def render?
    @partials.present?
  end

  class IteratingComponent < ApplicationComponent
    delegate :index, to: '@iterator'
    attr_reader :current_step

    def initialize(step:, iterator:)
      @step = step
      @iterator = iterator
    end

    private

    def active_class
      'active' if active?
    end

    def active?
      @iterator.index == @step
    end

    def stimulus_controller
      StepsComponent.name.underscore.gsub('/', '--').tr('_', '-')
    end

  end

  class HeaderComponent < IteratingComponent
    def initialize(header:, header_iteration:, step:)
      super(iterator: header_iteration, step: step)
      @header = header
    end

    def call
      content_tag(:li, markup, class: active_class)
    end

    private

    def markup
      return title unless index <= @step

      link_to(title, '#', data: { action: stimulus_action(:activate) })
    end

    def title
      I18n.t("sac_cas.groups.self_registration.form.#{@header}_title")
    end
  end

  class ContentComponent < IteratingComponent
    with_collection_parameter :partial

    public :stimulus_action

    def initialize(partial:, partial_iteration:, step:, form:)
      super(iterator: partial_iteration, step: step)
      @form = form
      @partial = partial.to_s
    end

    def call
      content_tag(:div, markup, class: %W[step-content #{@partial.dasherize} #{active_class}])
    end

    def next_button(title = t('steps_component.next_link'))
      helpers.submit_button(@form, title, name: :step, value: index)
    end

    def back_link
      link_to(t('global.button.back'), '#', class: 'link cancel', data: { action: stimulus_action(:back), index: index - 1 })
    end

    private

    def markup
      render(@partial, f: @form, c: self, required: false)
    end

  end
end
