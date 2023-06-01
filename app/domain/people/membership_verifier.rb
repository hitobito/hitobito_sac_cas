# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipVerifier

  MEMBERSHIP_ROLES = [
    Group::SektionsMitglieder::Einzel,
    Group::SektionsMitglieder::Jugend,
    Group::SektionsMitglieder::Familie
  ]

  def initialize(person)
    @person = person
  end

  def member?
    @person.roles.any? do |r|
      MEMBERSHIP_ROLES.include?(r.class)
    end
  end

end
