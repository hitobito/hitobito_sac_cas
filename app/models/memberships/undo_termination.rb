# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class UndoTermination
    include ActiveModel::Validations
    include MethodMemoizer

    attr_accessor :role

    def initialize(role)
      @role = role
      raise ArgumentError, "Must be called with a membership role" unless membership_role?
    end

    validates :mutation_id, presence: {message: :mutation_not_found}
    validate :validate_role_is_terminated
    validate :validate_roles_unchanged
    validate :validate_restored_roles
    validate :validate_household_keys_compatible

    def inspect
      "#<#{self.class.name}:#{object_id} role: #{role.id} - #{role.decorate}>"
    end

    # return the `mutation_id` for all entries changed by the termination
    # We find the mutation id by looking for the latest version of the role where the `terminated`
    # flag changed to `true`.
    def mutation_id # rubocop:todo Metrics/CyclomaticComplexity
      role&.versions&.reorder(created_at: :desc)&.find do |version|
        version.changeset.include?("terminated") && version.changeset.dig("terminated", 1)
      end&.mutation_id
    end

    # returns the versions of all roles changed by the termination
    def updated_roles_versions
      return [] unless mutation_id

      @updated_role_versions ||= role_versions_for_mutation
        .where.not(event: "create")
    end

    def created_roles_versions
      return [] unless mutation_id
      @created_role_versions ||= role_versions_for_mutation
        .where(event: "create")
    end

    # return all roles changed by the termination with their original values except for:
    # * the `end_on` attribute which is set to the current value of the role. This is necessary as
    #   the person might have paid the membership fee after the termination so after reverting
    #   the termination the role should be valid until the end of the paid period.
    # * the `start_on` attribute. This should usually never change, but when correcting the
    #   membership_years after the migration, it was changed for many roles. We want to keep
    #   the corrected `start_on` value, so we overwrite the value on the reified role.
    def restored_roles
      @restored_roles ||= updated_roles_versions.map do |version|
        version.reify.tap do |role|
          role.start_on = from_db(role).start_on
          role.end_on = [role.end_on, from_db(role).end_on].compact.max
        end
      end
    end

    # return all roles created by the termination
    def roles_to_destroy
      @roles_to_destroy ||= Role.unscoped.where(id: created_roles_versions.map(&:item_id))
    end

    # return all people whose roles have been changed by the termination, with their original
    # `household_key` value.
    # The only relevant change on people is on the attribute `household_key`. This will get
    # cleared eventually when dissolving the family/household after the SAC Membership
    # is terminated.
    def restored_people
      @restored_people ||= restored_roles_people.map do |person|
        person.household_key = original_household_key
        person.sac_family_main_person = true if original_family_main_person?(person)
        person
      end
    end

    # Save the restored roles and people, raises an error if the validation fails.
    def save!
      raise "Validation failed: #{errors.full_messages.join(", ")}" unless save
    end

    # Save the restored roles and people. Validation can be skipped, USE WITH CAUTION!
    def save(validate: true)
      return false unless !validate || valid?

      Role.transaction(requires_new: true) do
        # The validity is already ensured by calling #valid? before saving (unless skipped
        # explicitely), so we can safely skip the validations on save (we actually MUST skip it
        # here as the validations depend on the other roles being persisted, see
        # #validate_restored_roles for explanation).
        restored_people.each { _1.save(validate: false) if _1.changed? }
        restored_roles.each { _1.save(validate: false) }
        roles_to_destroy.each(&:destroy)
        role.person.reload.household.create_missing_people_managers
      end
      true
    end

    private

    ATTRS_ALLOWED_TO_CHANGE =
      %w[created_at updated_at end_on terminated termination_reason_id].freeze

    # We need to handle the case where one role was updated multiple times in the same
    # mutation (request/job run). In that case we have to restore the role to the state before
    # the first change with that mutation_id, so we order by item_id and id and with
    # SELECT DISTINCT ON (item_id) * we get the first change for each role.
    def role_versions_for_mutation
      PaperTrail::Version
        .where(mutation_id: mutation_id, item_type: "Role")
        .order(:item_id, :id)
        .select("DISTINCT ON (item_id) *")
    end

    def validate_role_is_terminated
      errors.add(:base, :role_not_terminated) unless role.terminated?
    end

    # validate that the roles have not been changed since the termination
    # This is the case when the role version created by the termination is the latest version
    # of the role.
    def validate_roles_unchanged
      restored_roles.each do |role|
        next if role_unchanged?(role)

        group_with_parent = role.group.decorate.label_with_parent
        person = role.person
        errors.add(:base, :role_changed, role:, group_with_parent:, person:)
      end
    end

    def roles_from_db
      @roles_latest_version ||= Role.unscoped.where(id: updated_roles_versions.map(&:item_id))
    end

    def from_db(role)
      roles_from_db.find { |r| role == r }
    end

    # check if the role has been changed since the termination
    # The role is considered unchanged if the role is terminated and the attributes are the same
    # as the attributes of the role version created by the termination, with the exception of the
    # `end_on` attribute which might have been changed after the termination, e.g. by paying the
    # membership fee which extends the membership.
    def role_unchanged?(role)
      role.attributes.except(*ATTRS_ALLOWED_TO_CHANGE) ==
        from_db(role).attributes.except(*ATTRS_ALLOWED_TO_CHANGE)
    end

    # Role validations depend on other roles persisted in the database. We need to validate
    # changes to multiple roles, this means that the validations of any of the roles
    # might only be successful once the other roles are persisted. To solve this, we first
    # persist all roles without validations and validate them afterwards, finally we roll back
    # the transaction to revert all changes.
    def validate_restored_roles # rubocop:todo Metrics/AbcSize
      Role.transaction(requires_new: true) do
        restored_people.each { _1.save(validate: false) }
        restored_roles.each { _1.save(validate: false) }

        restored_roles.each do |role|
          next if role.valid?

          group_with_parent = role.group.decorate.label_with_parent
          person = role.person
          role.errors.full_messages.each do |error_message|
            errors.add(:base, :role_invalid, role:, group_with_parent:, person:, error_message:)
          end
        end
        raise ActiveRecord::Rollback # revert all changes
      end
    end

    def validate_household_keys_compatible
      restored_people.each do |person|
        next if person.household_key_was.nil? || !person.household_key_changed?

        errors.add(:base, :household_changed, person: person)
      end
    end

    def membership_role? = SacCas::MITGLIED_ROLES.include?(role.class)

    def original_household_key
      restored_roles.find { |r| r.id == role.id }&.family_id
    end
    memoize_method :original_household_key

    def restored_roles_people = restored_roles.map(&:person).uniq

    def restored_main_person
      restored_roles_people.find do |person|
        person.versions.any? do |version|
          version.changeset.present? &&
            version.changeset.dig("sac_family_main_person", 1) == false
        end
      end
    end
    memoize_method :restored_main_person

    def original_family_main_person?(person) = restored_main_person == person
  end
end
