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

    with_options writable: false, sortable: false, filterable: false do
      attribute :family_id, :string
      attribute :membership_number, :integer do
        @object.membership_number if @object.sac_membership_anytime?
      end
      attribute :sac_remark_national_office, :string do
        @object.sac_remark_national_office if can?(:manage_national_office_remark, @object)
      end

      (1..5).each do |num|
        attribute :"sac_remark_section_#{num}", :string do
          @object.send(:"sac_remark_section_#{num}") if can?(:manage_section_remarks, @object)
        end
      end
    end
  end
end
