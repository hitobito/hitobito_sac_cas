# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Person
  extend ActiveSupport::Concern

  included do
    Person::INTERNAL_ATTRS += [:membership_verify_token]
    self.devise_login_id_attrs << :membership_number

    validates :membership_verify_token, uniqueness: { allow_blank: true }

    alias_attribute :membership_number, :id

    scope :with_membership_years, lambda { |selects: 'people.*'|
      subquery_sql = Group::SektionsMitglieder::Mitglied.
                     with_deleted.
                     with_membership_years(selects: 'roles.person_id').
                     to_sql

      select(*Array.wrap(selects), 'FLOOR(SUM(COALESCE(membership_years, 0))) as membership_years').
        joins("LEFT JOIN (#{subquery_sql}) AS subquery ON people.id = subquery.person_id").
        group('people.id')
    }
  end

  def membership_years
    read_attribute(:membership_years) or raise 'use Person scope :with_membership_years'
  end

  def family_id
    return unless roles.any? { |r| r.beitragskategorie&.familie? }

    /\AF/ =~ household_key ? household_key : "F#{household_key}"
  end

  def init_membership_verify_token!
    token = SecureRandom.base58(24)
    update!(membership_verify_token: token)
    token
  end
end
