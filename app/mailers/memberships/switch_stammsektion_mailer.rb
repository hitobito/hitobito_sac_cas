# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Memberships::SwitchStammsektionMailer < ApplicationMailer
  CONFIRMATION = "memberships_switch_stammsektion_confirmation"

  def confirmation(person, section, previous_section)
    @person = person
    @section = section
    headers[:cc] = Group::Geschaeftsstelle.first.email
    headers[:bcc] = [section.email, previous_section.email, SacCas::MV_EMAIL].compact_blank

    I18n.with_locale(person.language) do
      compose(person, CONFIRMATION)
    end
  end

  private

  def placeholder_person_name
    @person.to_s
  end

  def placeholder_group_name
    @section.to_s
  end

  def placeholder_person_id
    @person.id
  end
end
