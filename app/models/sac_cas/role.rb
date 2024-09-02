# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role
  module ClassMethods   
    def select_with_membership_years(date = Time.zone.today)
      # Because the parameter passed in the query is CET, we make sure to convert all database dates from UTC to CET.
      <<~SQL
        CASE
          -- membership_years is only calculated for Mitglied roles
          WHEN roles.type != 'Group::SektionsMitglieder::Mitglied' THEN 0
          ELSE (
            EXTRACT(YEAR FROM AGE(
              #{calculate_least_date(date)},
              roles.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET'
            ))
            + CASE
              -- check if dates are the same, to not add fractional year
              WHEN (
                DATE_PART('month', #{calculate_least_date(date)}) = DATE_PART('month', roles.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET') AND
                DATE_PART('day', #{calculate_least_date(date)}) = DATE_PART('day', roles.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET')
              ) THEN 0
              ELSE
                (
                  -- calculate the fractional year
                  (#{calculate_least_date(date)} - roles.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET' - 
                  INTERVAL '1 year' * EXTRACT(YEAR FROM AGE(
                    #{calculate_least_date(date)},
                    roles.created_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET'
                  ))) / CASE WHEN EXTRACT(DAY FROM DATE_TRUNC('year', #{calculate_least_date(date)}) + INTERVAL '1 year' - INTERVAL '1 day') = 29 THEN 366 ELSE 365 END
                )
            END
          )
        END AS membership_years
      SQL
    end
    
    def calculate_least_date(date)
      <<~SQL
        LEAST(
          '#{date.strftime("%Y-%m-%d")}'::date,
          COALESCE((roles.deleted_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET')::date + INTERVAL '1 day', '9999-12-31'),
          COALESCE((roles.archived_at AT TIME ZONE 'UTC' AT TIME ZONE 'CET')::date + INTERVAL '1 day', '9999-12-31'),
          COALESCE(roles.delete_on::date + INTERVAL '1 day', '9999-12-31')
        )
      SQL
    end    
  end

  def self.prepended(base)
    base.extend(ClassMethods)

    attr_writer :from_future_role

    base.class_eval do
      scope :with_membership_years,
        ->(selects = "roles.*", date = Time.zone.today) do
          select(selects, select_with_membership_years(date))
        end

      scope :family, -> {
        where(beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY)
      }

      scope :active, ->(date) {
        with_deleted
          .where(created_at: ..date.end_of_day)
          .where("(delete_on IS NULL OR delete_on >= :date) AND " \
                 "(deleted_at IS NULL OR deleted_at >= :datetime) AND " \
                 "(archived_at IS NULL OR archived_at >= :datetime)",
            date: date, datetime: date.beginning_of_day)
      }

      belongs_to :termination_reason, optional: true
    end
  end

  def from_future_role?
    @from_future_role
  end

  def termination_reason_text
    termination_reason&.text
  end

  def membership_years
    read_attribute(:membership_years) or raise "use Role scope :with_membership_years"
  end

  def start_on
    created_at&.to_date
  end

  def end_on
    [deleted_at&.to_date, archived_at&.to_date, delete_on].compact.min
  end

  protected

  def preferred_primary?
    SacCas::STAMMSEKTION_ROLES.map(&:sti_name).include?(type)
  end

  private

  def set_first_primary_group
    preferred_primary? ? set_preferred_primary! : super
  end

  def reset_primary_group
    preferred_primary? ? set_preferred_primary! : super
  end

  def set_preferred_primary!
    person.update!(primary_group: Groups::Primary.new(person).identify)
  end
end
