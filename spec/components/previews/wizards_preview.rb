# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class WizardsPreview < ViewComponent::Preview

  def choose_sektion_step(wizards_preview_wizard: {})
    wizard = build_wizard(Wizards::Steps::ChooseSektion, wizards_preview_wizard)
    render_wrapped(wizard)
  end

  def choose_sektion_step_with_alert(wizards_preview_wizard: {})
    wizard = build_wizard(Wizards::Steps::ChooseSektion, wizards_preview_wizard)
    render_wrapped(wizard) do |view_ctx, step|
      view_ctx.content_tag(:p, step.group&.name, class: 'alert alert-info') if step.group
    end
  end

  private

  def render_wrapped(wizard)
    render WrappingComponent.new do
      view_ctx = WizardsPreviewsController.new.view_context
      view_ctx.standard_form(wizard, url: '', authenticity_token: '', method: :get,
                                     data: { controller: 'autosubmit' }) do |f|
        step_component = StepsComponent.new(partials: wizard.partials, step: 0, form: f)
        content = yield(view_ctx, wizard.step_at(0)) if block_given?
        safe_join([content, view_ctx.render(step_component)].compact)
      end
    end
  end

  def build_wizard(step_class, params)
    self.class.const_set('Wizard', Class.new(Wizards::Base) { self.steps = [step_class] })
    Wizard.new(current_step: 0, current_ability: :current_ability,
               **params).tap { |w| w.valid? if params.present? }
  end

  class WrappingComponent < ViewComponent::Base
    haml_template <<~HAML
      = content
    HAML
  end

end
