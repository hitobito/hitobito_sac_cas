# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships::CommonApi
  def valid?
    super
    validate_roles
    errors.empty?
  end

  def save
    valid? && save_roles
  end

  def save!
    raise "cannot save invalid model: \n#{errors.full_messages}" unless valid?

    save
  end

  def affected_people
    person.sac_membership.family? ? person.household.people : [person]
  end

  def roles
    @roles ||= affected_people.flat_map { |p| prepare_roles(p) }
  end

  private

  def validate_roles
    # Validating roles is complicated because the validations check for other persisted roles.
    # So if we have changes for already persisted roles, we need to save those first before
    # validating new ones, otherwise the validations will check the old values as in the DB
    # instead of the new values.
    # But this method should not save the roles, so we must roll back after checking the validity.
    Role.transaction(requires_new: true) do
      roles_to_destroy, roles_to_update = roles.partition(&:marked_for_destruction?)
      roles_to_destroy.each { |role| role.delete }
      roles_to_update.each { |role| save_role_without_validations(role) }
      roles_to_update.each { |role| validate_role(role) }
      raise ActiveRecord::Rollback
    end
    errors.empty?
  end

  def save_role_without_validations(role)
    role.transaction(requires_new: true) do
      role.validate # required to trigger before_validation callbacks
      role.save(validate: false)
    rescue ActiveRecord::NotNullViolation, PG::NotNullViolation
      raise ActiveRecord::Rollback
    end
  end

  def validate_role(role)
    role.validate
    role.errors.full_messages.each do |msg|
      errors.add(:base, "#{role.person}: #{msg}")
    end
  end

  # prepare roles of correct type in correct subgroup of sektion
  # and with correct end_on date
  def prepare_roles(_person)
    []
  end

  def save_roles
    # As in #validate_roles, we must save existing roles first while ignoring validations.
    # See comments on #validate_roles for more details.
    Role.transaction do
      destroy_roles, update_roles = roles.partition(&:marked_for_destruction?)
      destroy_roles.each { |r| Role.with_inactive.find_by(id: r.id)&.really_destroy! }
      update_roles.each { |role| role.save(validate: false) }
      update_roles.each(&:save!)
    end
    update_primary_groups
    true
  end

  def update_primary_groups
    affected_people.each do |person|
      person.reload # Unsure why this reload is necessary
      person.update!(primary_group: Groups::Primary.new(person).identify)
    end
  end
end
