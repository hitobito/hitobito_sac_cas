# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::RoleResource
  extend ActiveSupport::Concern

  included do
    # type integer to round down to full membership years
    extra_attribute :membership_years, :integer, sortable: true, filterable: true do
      @object.membership_years if @object.is_a?(Group::SektionsMitglieder::Mitglied)
    end
    on_extra_attribute :membership_years do |scope|
      scope.with_membership_years
    end
  end
end
