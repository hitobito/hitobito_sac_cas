# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::JoinZusatzsektionMailer < ApplicationMailer
  include MultilingualMailer
  include CommonMailerPlaceholders

  CONFIRMATION = "join_zusatzsektion_confirmation"
  APPROVAL_PENDING_CONFIRMATION = "join_zusatzsektion_approval_pending_confirmation"

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
    locales = [person.language]

    compose_multilingual(person, content_key, locales)
  end

  def placeholder_person_ids
    if @person.sac_family_main_person && @beitragskategorie.to_s == SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s
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
    ApplicationController.render("wizards/signup/_section_fee_positions_table", layout: false, locals: {active: true, group: @section, presenter:}).html_safe
  end
end
