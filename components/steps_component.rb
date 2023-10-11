# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class StepsComponent < ApplicationComponent

  renders_one :submit_buttons
  renders_many :steps, 'StepComponent'

  attr_reader :form

  def render?
    steps.any?
  end

  def each_step
    steps.each do |step|
      yield step
    end
  end

  def link(key)
    css_classes = key == :next ? 'btn btn-primary' : 'link'
    link_to(t(".#{key}_link"), '', class: css_classes, data: { action: stimulus_action(key) })
  end

  private

  class StepComponent < ViewComponent::Base
    attr_reader :index

    def initialize(partial:, form:, index:, current_step: 0)
      @partial = partial
      @form = form
      @index = index
      @current_step = current_step
    end

    def title
      "Step #{index + 1}"
    end

    def header_class
      'active' if active?
    end

    def content_class
      'hidden' unless active?
    end

    def active?
      index == @current_step
    end

    def call
      render @partial.to_s, f: @form
    end
  end

end
