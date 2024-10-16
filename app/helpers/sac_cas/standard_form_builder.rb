# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::StandardFormBuilder

  # Add address dynamically to required attrs to render label as required, but not trigger the validation for required attrs
  # Event::ParticipationContactData#assert_required_contact_attrs_valid
  def dynamic_required?(attr)
    if @object.respond_to?(:required_attrs) && @object.required_attrs.include?(:street) && @object.required_attrs.include?(:housenumber)
      @object.required_attrs << :address
    end

    super
  end

  def labeled_gender_inline_radio_buttons
    checked = object.attributes["gender"].nil? ? {checked: false} : {}
    radios = (Person::GENDERS + [I18nEnums::NIL_KEY]).map do |key|
      inline_radio_button(:gender, key, Person.salutation_label(key), true, checked)
    end
    labeled(:gender, safe_join(radios))
  end

  def labeled_adult_required_field(attr, options = {}, &)
    content_tag(:div, class: "row mb-2") do
      content = input_field(attr, options)
      content += capture(&) if block_given?
      build_adult_label(attr) + build_adult_label(attr, optional: true) +
        content_tag(:div, content, class: "labeled col-md-9 col-lg-8 col-xl-8 mw-63ch")
    end
  end

  private

  def build_adult_label(attr, optional: false)
    classes = "col-md-3 col-xl-2 pb-1 col-form-label text-md-end"
    classes += " required" unless optional
    classes += " d-none" if (!optional && !object.adult?) || (optional && object.adult?)
    sac_target = optional ? "optionalLabel" : "requiredLabel"
    label_text = captionize(attr, klass)
    label(attr, label_text, class: classes, data: {"sac--signup_target": sac_target})
  end
end
