# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Wizards
  module Personal
    extend ActiveSupport::Concern

    included do
      attribute :person
      validates_presence_of :person
      validate :validate_person_is_member, if: :person
    end

    # Returns the current membership role of the person if one exists
    # or the latest expired membership role.
    # This is used to display wizard steps conditionally based on the
    # current membership status of the person.
    def membership_role
      return unless person

      Group::SektionsMitglieder::Mitglied.
        with_deleted.where(person_id: person.id).
        order(:deleted_at).
        last
    end

    def membership_terminated?
      membership_role&.terminated?
    end

    def family_membership?
      membership_role&.beitragskategorie ==
        SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY.to_s
    end

    def family_main_person?
      person&.sac_family_main_person? || false
    end

    def validate_person_is_member
      errors.add(:person, :not_a_member) if membership_role.nil?
    end
  end
end
