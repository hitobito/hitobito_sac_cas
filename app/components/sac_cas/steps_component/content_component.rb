# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::StepsComponent::ContentComponent
  extend ActiveSupport::Concern

  # Have not been able to render error messages and block in single fields_for call
  def fields_for(&)
    partial_name = @partial.split("/").last
    @form.fields_for(partial_name, model) do |form|
      form.error_messages
    end + @form.fields_for(partial_name, model, &) + bottom_toolbar
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
      safe_join([next_button, back_link])
    end
  end

  private

  # Adjust to comply with existing api
  def past?
    return super unless wizard?

    index < @form.object.current_step
  end

  def wizard?
    @form.object.is_a?(Wizards::Base)
  end
end
