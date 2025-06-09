# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoices::AboMagazin::AbonnentManager
  attr_reader :person, :group_or_role

  ABONNENT_ROLE_TYPE = Group::AboMagazin::Abonnent
  NEUANMELDUNG_ABONNENT_ROLE_TYPE = Group::AboMagazin::Neuanmeldung

  def initialize(person, group_or_role)
    @person = person
    @group_or_role = group_or_role
  end

  def group = group_or_role.is_a?(Group) ? group_or_role : group_or_role.group

  def role = group_or_role.is_a?(Role) ? group_or_role : nil

  def update_abonnent_status
    ActiveRecord::Base.transaction do
      if abonnent_role
        extend_role_by_one_year(abonnent_role)
      elsif expired_abonnent_role
        create_new_abonnent_role(expired_abonnent_role)
      elsif neuanmeldung_abonnent_role
        create_new_abonnent_role(neuanmeldung_abonnent_role, neuanmeldung_abonnent_role.start_on)
        remove_neuanmeldungs_role
      elsif expired_neuanmeldung_abonnent_role
        create_new_abonnent_role(expired_neuanmeldung_abonnent_role)
      end
    end
  end

  private

  def abonnent_role = @abonnent_role ||= find_role(ABONNENT_ROLE_TYPE, :active?)

  def expired_abonnent_role = @expired_abonnent_role ||= find_role(ABONNENT_ROLE_TYPE, :ended?, 1.year.ago..Time.zone.today)

  def neuanmeldung_abonnent_role = @neuanmeldung_abonnent_role ||= find_role(NEUANMELDUNG_ABONNENT_ROLE_TYPE, :active?)

  def expired_neuanmeldung_abonnent_role = @expired_neuanmeldung_abonnent_role ||= find_role(NEUANMELDUNG_ABONNENT_ROLE_TYPE, :ended?)

  def find_role(role_type, status, date_range = nil)
    role_matches?(role, status) ? role : role_by_type(role_type, status, date_range)
  end

  def role_matches?(role, status) = role.is_a?(role_type) && role.public_send(status)

  def role_by_type(role_type, status, date_range)
    query = person.roles.where(type: role_type.sti_name, group: group)
    query = query.with_inactive if status == :ended?
    query = query.where(end_on: date_range) if date_range
    query.first
  end

  def extend_role_by_one_year(role)
    role.update!(end_on: role.end_on + 1.year)
  end

  def create_new_abonnent_role(role, start_on = Time.zone.today)
    end_on = role.end_on.past? ? role.end_on + 1.year : role.start_on + 1.year
    return if start_on.jd > end_on.jd

    ABONNENT_ROLE_TYPE.create!(person: role.person,
      group: role.group,
      start_on: start_on,
      end_on: end_on)
  end

  def remove_neuanmeldungs_role
    neuanmeldung_abonnent_role.update(end_on: Time.zone.yesterday)
  end
end
