# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class WizardsPreview < ViewComponent::Preview

  def choose_sektion_form_step(wizards_base: {})
    setup_wrapping_component(Wizards::Steps::ChooseSektionForm, wizards_base) do |view_ctx, step|
      view_ctx.content_tag(:p, step.group&.name, class: 'alert alert-info') if step.group
    end
  end

  private

  def setup_wrapping_component(step_class, wizards_base)
    Wizards::Base.steps = [step_class]
    wizard = Wizards::Base.new(current_step: 0, current_ability: :current_ability, **wizards_base)
    view_ctx = WizardsPreviewsController.new.view_context
    wizard.valid? if wizards_base.present?
    f = StandardFormBuilder.new(:wizard, wizard, view_ctx, {})
    render WrappingComponent.new do
      view_ctx.standard_form(wizard, url: '', authenticity_token: '', method: :get,
                                     data: { controller: 'autosubmit' }) do |f|
        step_component = StepsComponent.new(partials: wizard.partials, step: 0, form: f)
        content = yield view_ctx, wizard.step_at(0)
        safe_join([content, view_ctx.render(step_component)].compact)
      end
    end
  end

  class WrappingComponent < ViewComponent::Base
    haml_template <<~HAML
      = content
    HAML
  end

end
