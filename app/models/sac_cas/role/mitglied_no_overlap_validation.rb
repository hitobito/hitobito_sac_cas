# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Role::MitgliedNoOverlapValidation
  extend ActiveSupport::Concern

  included do
    validate :assert_no_overlap, on: [:create, :update]
  end

  private

  def assert_no_overlap
    case self
    when SacCas::Role::MitgliedStammsektion
      assert_no_overlapping_primary_memberships
      assert_no_overlapping_memberships_per_layer
    when SacCas::Role::MitgliedZusatzsektion
      assert_no_overlapping_memberships_per_layer
    end
  end

  def assert_no_overlapping_primary_memberships
    overlapping_roles(active_period, SacCas::STAMMSEKTION_ROLES).tap do |conflicting_roles|
      conflicting_roles.each { |conflicting_role| add_overlap_error(conflicting_role) }
    end
  end

  def assert_no_overlapping_memberships_per_layer
    overlapping_roles(active_period, SacCas::MITGLIED_ROLES)
      .select { |role| role.layer_group == layer_group }.tap do |conflicting_roles|
      conflicting_roles.each { |conflicting_role| add_overlap_error(conflicting_role) }
    end
  end

  def overlapping_roles(period, role_types)
    person
      .roles
      .with_inactive
      .where(type: role_types.map(&:sti_name))
      .where.not(id: id)
      .to_a
      .select { |role| period.overlaps?(role.active_period) }
  end

  def add_overlap_error(conflicting_role)
    key = if /Neuanmeldung/.match?(conflicting_role.class.name)
      :already_has_neuanmeldung_role
    else
      :already_has_mitglied_role
    end

    from = format_date(conflicting_role.start_on)
    to = format_date(conflicting_role.end_on)

    errors.add(:person, key, start_on: from, end_on: to)
  end

  def role_sektion(role)
    role.group&.self_and_ancestors&.find_by(type: Group::Sektion.sti_name)
  end

  def format_date(date)
    I18n.l(date, format: :default) if date
  end
end
