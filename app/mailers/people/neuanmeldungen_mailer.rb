# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::NeuanmeldungenMailer < ApplicationMailer
  include MultilingualMailer

  APPROVED = "people_registration_approved"
  REJECTED = "people_registration_rejected"

  def approve(person, section)
    send_mail(person, section, APPROVED)
  end

  def reject(person, section)
    send_mail(person, section, REJECTED)
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

  def placeholder_sektion_name
    @section.to_s
  end

  def placeholder_profile_url
    group_person_url(@person.default_group_id, @person.id)
  end
end
