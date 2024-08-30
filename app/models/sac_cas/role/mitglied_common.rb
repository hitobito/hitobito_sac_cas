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

  DEPENDANT_ROLE_TYPES = ["Group::SektionsMitglieder::Ehrenmitglied",
    "Group::SektionsMitglieder::Beguenstigt",
    "Group::SektionsTourenkommission::Tourenleiter"].freeze

  included do
    self.permissions = []
    self.basic_permissions_only = true

    validates :start_on, presence: true

    after_create :check_data_quality
    after_destroy :hard_delete_dependant_roles, :check_data_quality
  end

  def soft_delete_dependant_roles
    dependant_roles.each { _1.destroy(always_soft_destroy: true) }
  end

  def hard_delete_dependant_roles
    dependant_roles.with_inactive.each { _1.really_destroy! }
  end

  def dependant_roles
    person
      .roles.joins(:group)
      .where(type: DEPENDANT_ROLE_TYPES, groups: {layer_group_id: group.layer_group_id})
  end

  def active_period
    [start_on, end_on].compact.min..end_on
  end

  private

  def check_data_quality
    People::DataQualityChecker.new(person).check_data_quality
  end
end
