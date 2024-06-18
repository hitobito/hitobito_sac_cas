# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas


module Memberships
  class MemberJoinSectionBase
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    validate :assert_person_is_sac_member
    validate :assert_person_not_member_of_join_section
    validate :assert_family_main_person, if: :validate_family_main_person?

    def initialize(join_section, person, join_date, **params)
      @join_section = join_section
      assert_sac_section_or_ortsgruppe!

      @person = person
      @join_date = join_date

      super(**params)
    end

    def valid?
      super && roles_valid?
    end

    def save
      valid? && save_roles.all?
    end

    def save!
      raise 'cannot save invalid model' unless valid?
      save
    end

    private

    def save_roles
      Role.transaction do
        roles.each(&:save!)
      end
    end

    def affected_people
      person.sac_family.member? ? person.sac_family.family_members : [person]
    end

    def roles
      @roles ||= affected_people.flat_map { |p| prepare_roles(p) }
    end

    def roles_valid?
      roles.each do |role|
        role.validate
        role.errors.full_messages.each do |msg|
          errors.add(:base, "#{role.person}: #{msg}")
        end
      end
    end

    # build roles of correct type in correct subgroup of sektion
    # and with correct dates (convert_on/delete_on)
    def prepare_roles(_person)
      []
    end

    def assert_person_is_sac_member
      unless sac_membership.active?
        errors.add(:person, :must_be_sac_member)
      end
    end

    def assert_person_not_member_of_join_section
      if sac_membership.active_or_pending_in?(join_section)
        errors.add(:person, :must_not_be_join_section_member)
      end
    end

    def assert_family_main_person
      unless person.roles.exists?(
        type: Group::SektionsMitglieder::Mitglied.sti_name,
        beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY
      ) && person.sac_family_main_person
        errors.add(:person, :must_be_family_main_person)
      end
    end

    def validate_family_main_person?
      false
    end

    def assert_sac_section_or_ortsgruppe!
      unless join_section.is_a?(Group::Sektion) || join_section.is_a?(Group::Ortsgruppe)
        raise 'must be section/ortsgruppe'
      end
    end

    def sac_membership
      People::SacMembership.new(person)
    end

    attr_reader :person, :join_section
  end
end
