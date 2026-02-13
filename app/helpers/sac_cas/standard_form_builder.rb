# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::StandardFormBuilder
  extend ActiveSupport::Concern

  prepended do
    alias_method :short_field, :number_field
  end

  # rubocop:todo Layout/LineLength
  # Add address dynamically to required attrs to render label as required, but not trigger the validation for required attrs
  # rubocop:enable Layout/LineLength
  # Event::ParticipationContactData#assert_required_contact_attrs_valid
  def required?(attr)
    (attr.to_s == "address") ? super(:street) && super(:housenumber) : super
  end

  def labeled_gender_inline_radio_buttons
    radios = (Person::GENDERS + [I18nEnums::NIL_KEY]).map do |key|
      inline_radio_button(:gender, key, Person.new(gender: key).gender_label)
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

  def build_adult_label(attr, optional: false) # rubocop:todo Metrics/CyclomaticComplexity
    classes = "col-md-3 col-xl-2 pb-1 col-form-label text-md-end"
    classes += " required" unless optional
    classes += " d-none" if (!optional && !object.adult?) || (optional && object.adult?)
    sac_target = optional ? "optionalLabel" : "requiredLabel"
    label_text = captionize(attr, klass)
    label(attr, label_text, class: classes, data: {"sac--signup_target": sac_target})
  end
end
