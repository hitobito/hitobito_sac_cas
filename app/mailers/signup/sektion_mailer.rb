# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Signup::SektionMailer < ApplicationMailer
  include MultilingualMailer

  CONFIRMATION = "sektion_signup_confirmation"
  APPROVAL_PENDING_CONFIRMATION = "sektion_signup_approval_pending_confirmation"

  def confirmation(person, section)
    send_mail(person, section, CONFIRMATION)
  end

  def approval_pending_confirmation(person, section)
    send_mail(person, section, APPROVAL_PENDING_CONFIRMATION)
  end

  private

  def send_mail(person, section, content_key)
    @person = person
    @section = section
    headers[:bcc] = [SacCas::MV_EMAIL, section.email].compact_blank
    locales = [person.language]

    compose_multilingual(person, content_key, locales)
  end

  def placeholder_first_name
    @person.first_name
  end

  def placeholder_last_name
    @person.last_name
  end

  def placeholder_birthday
    l(@person.birthday)
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

  def placeholder_section_name
    @section.to_s
  end

  def placeholder_membership_category
    t(@person.roles.first.beitragskategorie, scope: "roles.beitragskategorie")
  end

  def placeholder_invoice_details
    # Blocked by https://github.com/hitobito/hitobito_sac_cas/issues/933
    "TODO"
  end

  def placeholder_profile_url
    group_person_url(@person.default_group_id, @person.id)
  end

  def placeholder_faq_url
    t("global.links.faq")
  end
end
