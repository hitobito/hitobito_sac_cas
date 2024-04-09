# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role

  module ClassMethods # rubocop:disable Metrics/MethodLength
    def select_with_membership_years
      <<~SQL
      CASE
            -- membership_years is only calculated for Mitglied roles
            WHEN roles.type != 'Group::SektionsMitglieder::Mitglied' THEN 0
            ELSE (
                1 + 
                (CAST(DATE_PART('day', LEAST(
                    -- LEAST will return NULL if any of the arguments is NULL.
                    -- Any value that can be NULL must have a fallback value higher than today.
                    CURRENT_DATE,
                    COALESCE(DATE(roles.deleted_at), '9999-12-31'),
                    COALESCE(DATE(roles.archived_at), '9999-12-31'),
                    COALESCE(roles.delete_on, '9999-12-31')
                )) AS double precision) - CAST(DATE_PART('day', DATE(roles.created_at)) AS double precision))
                / 365
            )
        END AS membership_years
      SQL
    end
  end

  def self.prepended(base) 
    base.extend(ClassMethods)

    base.class_eval do
      scope :with_membership_years, ->(selects = 'roles.*') { select(selects,
                                                                     select_with_membership_years) }
    end
  end

  def membership_years
    read_attribute(:membership_years) or raise 'use Role scope :with_membership_years'
  end

  def start_on
    created_at&.to_date
  end

  def end_on
    [deleted_at&.to_date, archived_at&.to_date, delete_on].compact.min
  end

  protected

  def preferred_primary?
    SacCas::MITGLIED_HAUPTSEKTION_ROLES.include?(type.safe_constantize)
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
