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
    valid? && save_roles.all?
  end

  def save!
    raise "cannot save invalid model: \n#{errors.full_messages}" unless valid?

    save
  end

  private

  def roles
    @roles ||= affected_people.flat_map { |p| prepare_roles(p) }
  end

  def validate_roles
    # Validating roles is complicated because the validations check for other persisted roles.
    # So if we have changes for already persisted roles, we need to save those first before
    # validating new ones, otherwise the validations will check the old values as in the DB
    # instead of the new values.
    # But this method should not save the roles, so we must roll back after checking the validity.
    Role.transaction(requires_new: true) do
      roles.each do |role|
        # ignore the error, the role will be invalid anyway
        role.save(validate: false) rescue ActiveRecord::NotNullViolation
      end
      roles.each do |role|
        role.validate
        role.errors.full_messages.each do |msg|
          errors.add(:base, "#{role.person}: #{msg}")
        end
      end
      raise ActiveRecord::Rollback
    end
    errors.empty?
  end

  # prepare roles of correct type in correct subgroup of sektion
  # and with correct dates (convert_on/delete_on)
  def prepare_roles(_person)
    []
  end

  def save_roles
    # As in #validate_roles, we must save existing roles first while ignoring validations.
    # See comments on #validate_roles for more details.
    Role.transaction do
      roles.each { |role| role.save(validate: false) }
      roles.each(&:save!)
    end
  end

  def affected_people
    person.sac_family.member? ? person.sac_family.family_members : [person]
  end

end
