# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::StepsComponent::ContentComponent
  extend ActiveSupport::Concern

  # Have not been able to render error messages and block in single fields_for call
  def fields_for(buttons: true, &)
    partial_name = @partial.split("/").last
    content = @form.fields_for(partial_name, model) do |form|
      form.error_messages
    end
    content += @form.fields_for(partial_name, model, &)
    content += bottom_toolbar if buttons
    content
  end

  def nested_fields_for(assoc, object, &)
    fields_for(buttons: false) do |f|
      f.nested_fields_for(assoc, nil, nil, model_object: object, &)
    end
  end

  def form_error_messages
    @form.error_messages
  end

  def model
    @form.object.step_at(index)
  end

  def attr?(key)
    return false if key == :email && @partial =~ /main_person/

    super
  end

  def bottom_toolbar
    content_tag(:div, class: "btn-toolbar allign-with-form") do
      buttons = [next_button]
      buttons << if index.positive?
        back_link
      elsif persisted_person?
        cancel_link
      end
      safe_join(buttons)
    end
  end

  private

  def persisted_person?
    @form.object.try(:person).try(:persisted?)
  end

  def cancel_link
    link_to(t("global.button.cancel"), person_path(@form.object.person), class: "link cancel mt-2 pt-1")
  end
end
