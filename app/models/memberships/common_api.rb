# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships::CommonApi

  def valid?
    [super, roles_valid?].all?
  end

  def save
    valid? && save_roles.all?
  end

  def save!
    raise 'cannot save invalid model' unless valid?

    save
  end

  private

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

  # prepare roles of correct type in correct subgroup of sektion
  # and with correct dates (convert_on/delete_on)
  def prepare_roles(_person)
    []
  end

  def save_roles
    Role.transaction do
      roles.each(&:save!)
    end
  end

  def affected_people
    person.sac_family.member? ? person.sac_family.family_members : [person]
  end

end
