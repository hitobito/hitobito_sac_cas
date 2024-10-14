# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::NeuanmeldungenMailer < ApplicationMailer
  include MultilingualMailer

  # used since the record could be destroyed before the mail is sent
  Person = Data.define(:id, :email, :first_name, :language, :default_group_id)

  APPROVED = "people_registration_approved"
  REJECTED = "people_registration_rejected"

  def approve(person_record, section)
    person = create_data_person(person_record)
    send_mail(person, section, APPROVED)
  end

  def reject(person_record, section)
    person = create_data_person(person_record)
    send_mail(person, section, REJECTED)
  end

  private

  def send_mail(person, section, content_key)
    @person = person
    @section = section
    headers[:bcc] = [SacCas::MV_EMAIL, section.email].compact_blank
    locales = [person.language]

    compose_multilingual(person.email, content_key, locales)
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

  def create_data_person(record)
    Person.new(record.id,
      record.email,
      record.first_name,
      record.language,
      record.default_group_id)
  end
end
