# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class UndoTermination
    include ActiveModel::Validations
    include Memoizer

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

    # return the `mutation_id` for all entries changed by the termination
    # We find the mutation id by looking for the latest version of the role where the `terminated`
    # flag changed to `true`.
    def mutation_id
      memoized do
        role&.versions&.reorder(created_at: :desc)&.find do |version|
          version.changeset.include?("terminated") && version.changeset.dig("terminated", 1)
        end&.mutation_id
      end
    end

    # returns the versions of all roles changed by the termination
    def role_versions
      return [] unless mutation_id

      # we don't handle roles created with this mutation yet. If we want to support this,
      # we should include event: "create" in the query, but instead of reify we need to mark
      # them for deletion in #restored_roles and handle them correspondingly in #save!
      @role_versions ||= PaperTrail::Version
        .where(mutation_id: mutation_id, item_type: "Role")
        .where.not(event: "create")
        .includes(item: :versions)
    end

    # return all roles changed by the termination with their original values
    def restored_roles
      @restored_roles ||= role_versions.map(&:reify)
    end

    # return all people changed by the termination with their original `household_key` value.
    # The only relevant change on people is on the attribute `household_key`. This will get
    # cleared eventually when dissolving the family/household after the SAC Membership
    # is terminated.
    def restored_people
      @restored_people ||= affected_family_people.map do |person|
        person.household_key = original_household_key
        person
      end.select(&:changed?)
    end

    # save the restored roles and people
    # Roles can only be validated after saving (see #validate_restored_roles for explanation).
    # The roles validity is already ensured by calling #valid? before saving, so we can safely
    # skip the validations on save.
    def save!
      raise "Validation failed: #{errors.full_messages.join(", ")}" unless valid?

      Role.transaction(requires_new: true) do
        restored_roles.each { _1.save(validate: false) }
        restored_people.each { _1.save(validate: false) }
      end
    end

    private

    def validate_role_is_terminated
      errors.add(:base, :role_not_terminated) unless role.terminated?
    end

    # validate that the roles have not been changed since the termination
    # This is the case when the role version created by the termination is the latest version
    # of the role.
    def validate_roles_unchanged
      role_versions.each do |version|
        role = version.item || Role.unscoped.find(version.item_id)
        next if role.versions.order(created_at: :desc).first == version

        group_with_parent = role.group.decorate.label_with_parent
        person = role.person
        errors.add(:base, :role_changed, role: version.item, group_with_parent:, person:)
      end
    end

    # Role validations depend on other roles persisted in the database. We need to validate
    # changes to multiple roles, this means that the validations of any of the roles
    # might only be successful once the other roles are persisted. To solve this, we first
    # persist all roles without validations and validate them afterwards, finally we roll back
    # the transaction to revert all changes.
    def validate_restored_roles
      Role.transaction(requires_new: true) do
        restored_roles.each { _1.save(validate: false) }
        restored_people.each { _1.save(validate: false) }

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

    def membership_role? = role.is_a?(SacCas::Role::MitgliedCommon)

    def affected_family_people
      family_roles = restored_roles.select do |r|
        r.is_a?(SacCas::Role::MitgliedCommon) && r.family?
      end
      Person.unscoped.where(id: family_roles.map(&:person_id).uniq)
    end

    def original_household_key
      memoized do
        restored_roles.find { |r| r.id == role.id }&.family_id
      end
    end
  end
end
