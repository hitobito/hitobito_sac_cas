# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class TerminatedMitglieder < Export::Tabular::SacGroupPeopleBase
    ATTRIBUTES = [
      :id,
      :sektion,
      :sac_is_terminated,
      :sac_is_section_switch,
      :terminate_on,
      :termination_reason,
      :data_protection_agreement,
      :type,
      :beitragskategorie,
      :membership_years,
      :sac_entry_on,
      :sektion_entry_on,
      :ehrenmitglied,
      :beguenstigt,
      :last_name,
      :first_name,
      :gender,
      :birthday,
      :correspondence,
      :email,
      :phone_number_mobile,
      :phone_number_landline,
      :postbox,
      :street,
      :housenumber,
      :address_care_of,
      :zip_code,
      :town,
      :country
    ]

    def initialize(group, user_id, from, to)
      @group = group
      @user_id = user_id
      @from = from
      @to = to
      super(people_scope, group)
    end

    def attributes
      ATTRIBUTES
    end

    def sheet_name
      [
        @from.strftime("%Y%m%d"),
        @to.strftime("%Y%m%d")
      ].join("_")
    end

    def people_scope
      group_people.with_membership_years
      # people_with_membership_years
      #   .includes(:phone_number_landline, :phone_number_mobile, :roles_unscoped)
      #   .order_by_name
      #   .distinct
    end

    private

    def group_people
      readable_people
        .joins(:roles)
        .where(roles: {
          group_id: group.id,
          type: SacCas::MITGLIED_ROLES.map(&:sti_name)
        })
    end

    def user
      @user ||= Person.find(@user_id)
    end

    def readable_people
      ability = PersonReadables.new(user, group)
      Person.accessible_by(ability)
    end

    def attribute_label(attr)
      I18n.t("export/tabular/people.attributes.#{attr}")
    end
  end
end
