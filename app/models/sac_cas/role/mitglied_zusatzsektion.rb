# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Role::MitgliedZusatzsektion
  extend ActiveSupport::Concern

  include SacCas::Role::MitgliedCommon

  included do
    validate :assert_is_mitglied_during_validity_period, on: [:create, :update]
  end

  def assert_is_mitglied_during_validity_period
    member_roles = Group::SektionsMitglieder::Mitglied.where(person_id: person_id)

    return if member_roles.any? do |role|
      role.active_period.cover?(active_period)
    end

    errors.add(:person, :must_have_mitglied_role)
  end

end
