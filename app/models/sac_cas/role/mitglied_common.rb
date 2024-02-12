# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role::MitgliedCommon
  extend ActiveSupport::Concern

  include SacCas::Role::MitgliedFamilyValidations
  include SacCas::Role::MitgliedMinimalAgeValidation
  include SacCas::Role::MitgliedNoOverlapValidation
  include SacCas::RoleBeitragskategorie

  DEPENDANT_ROLE_TYPES = ['Group::SektionsMitglieder::Ehrenmitglied',
                          'Group::SektionsMitglieder::Beguenstigt']

  included do
    self.permissions = []
    self.basic_permissions_only = true

    validates :created_at, presence: true

    after_destroy :soft_delete_dependant_roles
    after_real_destroy :hard_delete_dependant_roles
  end

  def soft_delete_dependant_roles
    dependant_roles.update_all(deleted_at: deleted_at)
  end

  def hard_delete_dependant_roles
    dependant_roles.destroy_all
  end

  def dependant_roles
    person.roles.where(type: DEPENDANT_ROLE_TYPES, group: group)
  end

end
