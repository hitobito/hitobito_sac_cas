# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module CommonMailerPlaceholders
  def placeholder_first_name
    @person.first_name
  end

  def placeholder_last_name
    @person.last_name
  end

  def placeholder_birthday
    l(@person.birthday) if @person.birthday
  end

  def placeholder_email
    @person.email
  end

  def placeholder_phone_number
    @person.phone_numbers.first
  end

  def placeholder_address_care_of
    @person.address_care_of
  end

  def placeholder_street_with_number
    @person.address
  end

  def placeholder_postbox
    @person.postbox
  end

  def placeholder_zip_code
    @person.zip_code
  end

  def placeholder_town
    @person.town
  end

  def placeholder_country
    @person.country
  end

  def placeholder_profile_url
    person_url(@person.id)
  end

  def placeholder_profile_links
    safe_join(@person.household.people.map { link_to(_1.full_name, person_url(_1)) }, raw("<br />"))
  end

  def placeholder_faq_url
    t("global.links.faq")
  end

  def placeholder_person_ids
    # rubocop:todo Layout/LineLength
    if @person.sac_family_main_person && @beitragskategorie.to_s == SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s
      # rubocop:enable Layout/LineLength
      family_ids = @person.household_people.distinct.order(:id).pluck(:id)
      family_ids.present? ? "#{@person.id} (#{family_ids.join(", ")})" : @person.id
    else
      @person.id
    end
  end

  def placeholder_section_name
    @section.to_s
  end

  def placeholder_membership_category
    t(@beitragskategorie, scope: "roles.beitragskategorie")
  end

  def placeholder_invoice_details
    presenter = Invoices::SacMemberships::SectionSignupFeePresenter.new(
      @section,
      @beitragskategorie,
      @person,
      main: false
    )
    ApplicationController.render("wizards/signup/_section_fee_positions_table", layout: false,
      locals: {active: true, group: @section, presenter:}).html_safe
  end
end
