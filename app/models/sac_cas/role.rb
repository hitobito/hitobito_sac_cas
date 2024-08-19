# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role
  module ClassMethods
    def select_with_membership_years(date = Time.zone.today)
      <<~SQL
          CASE
            -- membership_years is only calculated for Mitglied roles
            WHEN roles.type != 'Group::SektionsMitglieder::Mitglied' THEN 0
            ELSE (
                TIMESTAMPDIFF(
                    YEAR, 
                    DATE(roles.created_at), 
                    LEAST(
                        CURDATE(),
                        COALESCE(DATE(roles.deleted_at), '9999-12-31'),
                        COALESCE(DATE(roles.archived_at), '9999-12-31'),
                        COALESCE(roles.delete_on, '9999-12-31')
                    )
                ) 
                -- Add 1 year if the created_at is Jan 1st and the end_date is Dec 31st
                + CASE 
                    WHEN DATE_FORMAT(DATE(roles.created_at), '%m-%d') <= '01-01' 
                         AND DATE_FORMAT(
                             LEAST(
                                CURDATE(),
                                COALESCE(DATE(roles.deleted_at), '9999-12-31'),
                                COALESCE(DATE(roles.archived_at), '9999-12-31'),
                                COALESCE(roles.delete_on, '9999-12-31')
                            ), 
                            '%m-%d'
                         ) = '12-31'
                    THEN 1 
                    ELSE 0 
                  END
            )
        END AS membership_years
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
