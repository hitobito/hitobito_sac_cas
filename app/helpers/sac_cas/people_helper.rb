# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleHelper
  def format_person_membership_years(person)
    f(person.membership_years.floor)
  end

  def format_person_sac_family_main_person(person)
    main_person = person.household.main_person

    if person == main_person
      f(true)
    elsif main_person.nil?
      ti(".unknown")
    elsif can?(:show, main_person)
      link_to(main_person.to_s, main_person)
    else
      main_person.to_s
    end
  end

  def people_sac_membership_qr_code(person, html_options = {})
    pass = sac_membership_pass(person)
    return unless pass

    image = pass_qr_code_svg(pass, size: 220)

    if Rails.env.development?
      people_sac_membership_qr_code_clickable(pass, image)
    else
      image
    end
  end

  def format_person_data_quality(person)
    format_data_quality_icons(person.data_quality)
  end

  def format_data_quality_icons(status)
    icons = {
      ok: "check-circle",
      info: "info-circle",
      warning: "exclamation-triangle",
      error: "times-circle"
    }
    icon_name = icons[status.to_sym]
    icon(icon_name, title: I18n.t("people.data_quality.#{status}"))
  end

  private

  def sac_membership_pass(person)
    key = Settings.passes.legacy_verify_pass_definition_key
    pass = if @passes
      @passes.find { |p| p.pass_definition.template_key == key }
    else
      person.passes.joins(:pass_definition)
        .find_by(pass_definitions: {template_key: key})
    end
    pass&.decorate
  end

  def people_sac_membership_qr_code_clickable(pass, image)
    link_to(pass.qrcode_value, target: "_blank", rel: "noopener") do
      image
    end
  end
end
