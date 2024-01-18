#  frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

module SacCas::PersonResource
  extend ActiveSupport::Concern

  included do
    attribute :family_id, :string, writable: false, sortable: false, filterable: false
    attribute :membership_number, :integer, writable: false, sortable: false, fiterable: false do
      @object.membership_number if @object.membership_anytime?
    end

    extra_attribute :membership_years, :integer, sortable: true, filterable: true do
      @object.membership_years if @object.membership_anytime?

    end
    on_extra_attribute :membership_years do |scope|
      scope.with_membership_years
    end
  end
end
