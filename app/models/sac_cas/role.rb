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
          -- membership_years is only calculated for 'Group::SektionsMitglieder::Mitglied' roles
          WHEN roles.type != 'Group::SektionsMitglieder::Mitglied' THEN 0
          ELSE
            EXTRACT(YEAR FROM AGE(#{calculated_end_date(date)}, #{calculated_start_date(date)}))::int
            +
            CASE
              -- Check if the month and day are the same to avoid adding fractional year
              WHEN (
                EXTRACT(MONTH FROM #{calculated_end_date(date)}) = EXTRACT(MONTH FROM #{calculated_start_date(date)}) AND
                EXTRACT(DAY FROM #{calculated_end_date(date)}) = EXTRACT(DAY FROM #{calculated_start_date(date)})
              ) THEN 0
              ELSE
                -- Calculate the fractional year
                (
                  EXTRACT(DAY FROM (#{calculated_end_date(date)}::date - 
                    (#{calculated_start_date(date)} 
                    + (EXTRACT(YEAR FROM AGE(#{calculated_end_date(date)}, #{calculated_start_date(date)}))::int || ' years')::interval)
                  ))::numeric
                )
                /
                (
                  -- Determine if the current year is a leap year (366 days) or not (365 days)
                  CASE 
                    WHEN (DATE_TRUNC('year', #{calculated_end_date(date)}) + INTERVAL '1 year')::date 
                      - DATE_TRUNC('year', #{calculated_end_date(date)})::date = 366
                  THEN 366
                  ELSE 365
                  END
                )::numeric
          END
        END AS membership_years, '#{date.strftime("%Y-%m-%d")}'::date AS testdate 
      SQL
    end

    def calculated_start_date(date)
      <<~SQL
        LEAST(
          '#{date.strftime("%Y-%m-%d")}'::date,
          COALESCE(roles.start_on, '9999-12-31'::date)
        )
      SQL
    end

    def calculated_end_date(date)
      <<~SQL
        LEAST(
          '#{date.strftime("%Y-%m-%d")}'::date,
          COALESCE(roles.archived_at::date + INTERVAL '1 day', '9999-12-31'::date),
          COALESCE(roles.end_on + INTERVAL '1 day', '9999-12-31'::date)
        )
      SQL
    end
  end

  def self.prepended(base)
    base.extend(ClassMethods)

    base.class_eval do
      scope :with_membership_years,
        ->(selects = "roles.*", date = Time.zone.today) do
          select(selects, select_with_membership_years(date))
        end

      scope :family, -> {
        where(beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY)
      }

      belongs_to :termination_reason, optional: true
    end
  end

  def termination_reason_text
    termination_reason&.text
  end

  def membership_years
    read_attribute(:membership_years) or raise "use Role scope :with_membership_years"
  end

  protected

  def preferred_primary?
    SacCas::STAMMSEKTION_ROLES.map(&:sti_name).include?(type)
  end
end
