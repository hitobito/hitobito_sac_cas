# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class Mitgliedschaft < Export::Tabular::SacGroupPeopleBase
    ROLE_ATTRIBUTES = [
      :type,
      :beitragskategorie,
      :membership_years,
      :sac_entry_on,
      :sektion_entry_on,
      :ehrenmitglied,
      :beguenstigt
    ].freeze

    PERSON_ATTRIBUTES = [
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
    ].freeze

    class_attribute :attributes

    def initialize(group, user_id, range)
      @group = group
      @user_id = user_id
      @range = range
      super(people_scope, group)
    end

    def sheet_name
      [
        @range.begin.strftime("%Y%m%d"),
        @range.end.strftime("%Y%m%d")
      ].join("_")
    end

    def people_scope
      readable_people
        .includes(:phone_number_landline, :phone_number_mobile, :roles_unscoped)
        .where("people.id IN (?)", relevant_person_ids) # rubocop:disable Rails/WhereEquals
        .order_by_name
        .select("people.*") # order_by_name clears selected columns
        .distinct
    end

    private

    def relevant_person_ids
      raise NotImplementedError
    end

    def user
      @user ||= Person.find(@user_id)
    end

    def readable_people
      ability = PersonReadables.new(user, group, include_ended_roles: true)
      Person.accessible_by(ability)
    end

    def attribute_label(attr)
      I18n.t("export/tabular/people/mitgliedschaft.attributes.#{attr}")
    end

    def row_for(entry, format = nil)
      row_class.new(entry, @group, @range, format)
    end
  end
end
