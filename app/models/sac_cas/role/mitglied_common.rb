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

  ROLES_TO_DESTROY_ON_MEMBERSHIP_TERMINATION = ["Group::SektionsMitglieder::Ehrenmitglied",
    "Group::SektionsMitglieder::Beguenstigt",
    "Group::SektionsTourenUndKurse::Tourenleiter"].freeze

  included do
    self.permissions = []
    self.basic_permissions_only = true

    validates :start_on, presence: true

    after_create :check_data_quality

    after_destroy :destroy_dependant_roles, :check_data_quality
    attr_accessor :skip_destroy_dependent_roles
  end

  def destroy_dependant_roles
    return if skip_destroy_dependent_roles

    if destroyed?
      dependant_roles.each { _1.really_destroy! }
    else
      dependant_roles.each { _1.destroy }
    end
  end

  def dependant_roles
    person
      .roles.joins(:group)
      .where(type: ROLES_TO_DESTROY_ON_MEMBERSHIP_TERMINATION, groups: {layer_group_id: group.layer_group_id})
  end

  private

  def check_data_quality
    People::DataQualityChecker.new(person).check_data_quality
  end
end
