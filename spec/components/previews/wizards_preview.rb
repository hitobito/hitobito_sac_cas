# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class WizardsPreview < ViewComponent::Preview
  ## step and next param are old steps component api
  def join_zusatzsektion_wizard(current_step: 0, step: 0, next: nil,
    person_id: Group::SektionsMitglieder::Mitglied.first.person.id,
    wizards_memberships_join_zusatzsektion: {})
    next_step = begin
      Integer(binding.local_variable_get(:next))
    rescue
      nil
    end
    person = Person.find(person_id)
    wizard = Wizards::Memberships::JoinZusatzsektion.new(
      current_step: step.to_i,
      person: person,
      **wizards_memberships_join_zusatzsektion
    )
    if wizard.valid? && step.to_i < next_step.to_i
      wizard.move_on
    end

    render_wrapped(wizard) do |view_ctx|
      view_ctx.content_tag(:div, class: "alert alert-info") do
        content = [
          view_ctx.content_tag(:p,
            "Rendering as #{person} with sac_family:  #{person.sac_family_main_person}"),
          view_ctx.link_to("Reset", "/rails/view_components/wizards/join_zusatzsektion_wizard")

        ]
        safe_join(content)
      end
    end
  end

  def choose_sektion_step(wizards_preview_wizard: {})
    wizard = build_wizard(Wizards::Steps::ChooseSektion, wizards_preview_wizard)
    def wizard.backoffice?
      false
    end
    render_wrapped(wizard)
  end

  def choose_sektion_step_with_alert(wizards_preview_wizard: {})
    wizard = build_wizard(Wizards::Steps::ChooseSektion, wizards_preview_wizard)
    render_wrapped(wizard) do |view_ctx, step|
      view_ctx.content_tag(:p, step.group&.name, class: "alert alert-info") if step.group
    end
  end

  def main_email_form_step(wizards_preview_wizard: {})
    wizard = build_wizard(Wizards::Steps::MainEmail, wizards_preview_wizard)
    render_wrapped(wizard) do |view_ctx, step|
      view_ctx.content_tag(:p, step.email, class: "alert alert-info") if step.email
    end
  end

  def membership_terminated_info(wizards_preview_wizard: {})
    wizard = build_wizard(Wizards::Steps::MembershipTerminatedInfo, wizards_preview_wizard)
    def wizard.person
      Group::SektionsMitglieder::Mitglied.first.person
    end
    render_wrapped(wizard)
  end

  private

  def render_wrapped(wizard)
    render WrappingComponent.new do
      view_ctx = WizardsPreviewsController.new.view_context
      view_ctx.standard_form(wizard, url: "", authenticity_token: "", method: :get,
        data: {controller: "autosubmit forwarder"}) do |f|
        step_component = StepsComponent.new(partials: wizard.partials, step: wizard.current_step,
          form: f)
        current_step = wizard.step_at(wizard.current_step)
        content = yield(view_ctx, current_step) if block_given?
        safe_join([content, view_ctx.render(step_component)].compact)
      end
    end
  end

  def build_wizard(step_class, params)
    self.class.const_set(:Wizard, Class.new(Wizards::Base) { self.steps = [step_class] })
    Wizard.new(current_step: 0, **params).tap { |w| w.valid? if params.present? }
  end

  class WrappingComponent < ViewComponent::Base
    haml_template <<~HAML
      = content
    HAML
  end
end
