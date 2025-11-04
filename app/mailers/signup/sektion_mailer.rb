# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Signup::SektionMailer < ApplicationMailer
  include CommonMailerPlaceholders

  CONFIRMATION = "sektion_signup_confirmation"
  APPROVAL_PENDING_CONFIRMATION = "sektion_signup_approval_pending_confirmation"

  def confirmation(person, section, beitragskategorie)
    send_mail(person, section, beitragskategorie, CONFIRMATION)
  end

  def approval_pending_confirmation(person, section, beitragskategorie)
    send_mail(person, section, beitragskategorie, APPROVAL_PENDING_CONFIRMATION)
  end

  private

  def send_mail(person, section, beitragskategorie, content_key)
    @person = person
    @section = section
    @beitragskategorie = beitragskategorie
    headers[:bcc] = [section.email, SacCas::MV_EMAIL].compact_blank

    I18n.with_locale(person.language) do
      compose(person, content_key)
    end
  end

  def placeholder_person_ids
    if family_main_person?
      family_ids = @person.household_people.distinct.order(:id).pluck(:id)
      family_ids.present? ? "#{@person.id} (#{family_ids.join(", ")})" : @person.id
    else
      @person.id
    end
  end

  def family_main_person?
    @person.sac_family_main_person &&
      @beitragskategorie.to_s == SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s
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
      main: true
    )
    ApplicationController.render("wizards/signup/_section_fee_positions_table", layout: false,
      locals: {active: true, group: @section, presenter:}).html_safe
  end
end
