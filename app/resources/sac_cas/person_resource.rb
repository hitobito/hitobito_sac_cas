#  frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

module SacCas::PersonResource
  extend ActiveSupport::Concern

  included do
    extra_attribute :membership_years, :integer, sortable: true, filterable: true do
      @object.membership_years if @object.sac_membership_anytime?
    end
    on_extra_attribute :membership_years do |scope|
      scope.with_membership_years
    end

    with_options writable: false, sortable: false, filterable: false do
      attribute :family_id, :string
      attribute :membership_number, :integer do
        @object.membership_number if @object.sac_membership_anytime?
      end
      extra_attribute :sac_remark_national_office, :string, readable: :can_read_national_office_remark?
  
      (1..5).each do |num|
        extra_attribute :"sac_remark_section_#{num}", :string, readable: :can_read_section_remarks?
      end
    end

    def can_read_national_office_remark?(person)
      can?(:manage_national_office_remark, person)
    end
    
    def can_read_section_remarks?(person)
      can?(:manage_section_remarks, person)
    end
  end
end
