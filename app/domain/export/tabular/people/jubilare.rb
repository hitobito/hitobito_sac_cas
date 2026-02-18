# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class Jubilare < Export::Tabular::SacGroupPeopleBase
    ATTRIBUTES = [
      :id,
      :url,
      :sektion,
      :membership_years,
      :sac_entry_on,
      :sektion_entry_on,
      :terminate_on,

      :type,
      :beitragskategorie,
      :ehrenmitglied,
      :beguenstigt,

      *Mitgliedschaft::PERSON_ATTRIBUTES
    ]

    self.styled_attrs = {
      date: [:sac_entry_on, :sektion_entry_on, :terminate_on, :birthday]
    }

    def initialize(group, user_id, reference_date, membership_years)
      @group = group
      @user_id = user_id
      @reference_date = reference_date
      @membership_years = membership_years
      super(people_scope, group)
    end

    def attributes
      ATTRIBUTES
    end

    def sheet_name
      I18n.t("export/tabular/people/jubilare.sheet_name",
        reference_date: @reference_date.strftime("%Y%m%d"))
    end

    def people_scope
      people_with_membership_years
        .includes(:phone_number_landline, :phone_number_mobile, :roles_unscoped)
        .order_by_name
        .distinct
    end

    private

    def people_with_membership_years
      # Because all membership roles end with the current year,
      # with a reference_date in a future year, the future membership years
      # cannot be calculated by `with_membership_years`.
      # As a workaround, we calculate the membership years for the reference date in the
      # current year and add the difference to the future reference_date manually.
      date = @reference_date - membership_years_offset.years
      scope = group_people.with_membership_years("people.*", date)
      if @membership_years
        scope = scope.where(membership_years: @membership_years - membership_years_offset)
      end
      scope
    end

    def group_people
      end_on = [@reference_date, Time.zone.today].min
      roles = Role
        .unscoped
        .where(
          group_id: group.id,
          type: SacCas::MITGLIED_ROLES.map(&:sti_name),
          start_on: ..@reference_date,
          end_on: end_on..
        )
      Person.where(id: roles.select(:person_id))
    end

    def membership_years_offset
      @membership_years_offset ||=
        (@reference_date.year > current_year) ? @reference_date.year - current_year : 0
    end

    def current_year
      @current_year ||= Date.current.year
    end

    def user
      @user ||= Person.find(@user_id)
    end

    def values(entry, format = nil)
      return super unless membership_years_offset.positive?

      super.tap { _1[membership_years_attr_index] += membership_years_offset }
    end

    def membership_years_attr_index
      @membership_years_attr_index ||= attributes.find_index(:membership_years)
    end

    def attribute_label(attr)
      I18n.t("export/tabular/people/mitgliedschaft.attributes.#{attr}")
    end
  end
end
