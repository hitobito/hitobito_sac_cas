# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role::NeuanmeldungCommon
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_family_neuanmeldungen, if: :family?
  end

  def destroy_family_neuanmeldungen
    Role.where(type: SacCas::NEUANMELDUNG_ROLES.map(&:sti_name),
      person_id: family_mitglieder.pluck(:id)).destroy_all
  end

  def family_mitglieder
    Household.new(person).people
  end
end
