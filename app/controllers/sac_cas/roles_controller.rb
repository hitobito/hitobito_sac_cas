# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::RolesController
  extend ActiveSupport::Concern

  prepended do
    after_destroy :resolve_household_for_neuanmeldung
  end

  private

  def resolve_household_for_neuanmeldung
    destroy_family_neuanmeldungen if family_neuanmeldungs_role?
    destroy_household if neuanmeldungs_stammsektion_role?
  end

  def neuanmeldungs_stammsektion_role?
    ::SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES.map(&:sti_name).include?(entry.type)
  end

  def family_neuanmeldungs_role?
    ::SacCas::NEUANMELDUNG_ROLES.map(&:sti_name).include?(entry.type) && entry.family?
  end

  def destroy_household
    Household.new(entry.person).destroy
  end

  def destroy_family_neuanmeldungen
    Role.where(type: SacCas::NEUANMELDUNG_ROLES.map(&:sti_name),
      person_id: family_mitglieder.pluck(:id)).destroy_all
  end

  def family_mitglieder
    Household.new(person).people
  end
end
