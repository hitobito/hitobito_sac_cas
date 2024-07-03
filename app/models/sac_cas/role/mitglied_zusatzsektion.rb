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
    # validation can be skipped by setting this attribute to truthy
    # This is used by the import as we don't have the complete memberhip history of a person
    # but have to import MitgliedZusatzsektion roles anyway.
    return if try(:skip_mitglied_during_validity_period_validation)

    # to simplify, only validate if both dates are set (otherwise the role will be invalid anyway)
    return unless start_on && end_on

    days_to_check = active_period.to_a

    Group::SektionsMitglieder::Mitglied.with_deleted.where(person_id: person_id).each do |mitglied|
      days_to_check -= mitglied.active_period.to_a
    end

    errors.add(:person, :must_have_mitglied_role) if days_to_check.any?
  end
end
