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
  ].freeze

  def initialize(person)
    @person = person
  end

  def member?
    membership_roles.any?
  end

  def membership_roles
    @membership_roles ||= @person.roles.select do |r|
      MEMBERSHIP_ROLES.include?(r.class)
    end.compact
  end

end
