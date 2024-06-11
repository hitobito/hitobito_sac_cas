# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Person
  extend ActiveSupport::Concern

  included do
    CORRESPONDENCES = ['digital', 'print']

    Person::LANGUAGES.delete(:en)

    devise_login_id_attrs << :membership_number

    Person.used_attributes.delete(:nickname)

    reflect_on_attachment(:picture).variant(:profile, resize_to_fill: [200, 200])

    has_many :external_trainings
    has_many :roles_with_deleted, -> { with_deleted }, class_name: 'Role', foreign_key: 'person_id'

    delegate :active?, :anytime?, :roles, to: :sac_membership, prefix: true

    alias_attribute :membership_number, :id
    alias_attribute :navision_id, :id

    i18n_enum :correspondence, CORRESPONDENCES
    i18n_setter :correspondence, CORRESPONDENCES

    before_save :set_digital_correspondence, if: :password_initialized?

    scope :with_membership_years, lambda { |selects = 'people.*', date = Time.zone.today|
      subquery_sql = Group::SektionsMitglieder::Mitglied.
                     with_deleted.
                     with_membership_years('roles.person_id', date).
                     to_sql

      select(*Array.wrap(selects), 'FLOOR(SUM(COALESCE(membership_years, 0))) as membership_years').
        joins("LEFT JOIN (#{subquery_sql}) AS subquery ON people.id = subquery.person_id").
        group('people.id')
    }
  end

  def membership_years
    read_attribute(:membership_years) or raise 'use Person scope :with_membership_years'
  end

  def set_digital_correspondence
    self.correspondence = 'digital'
  end

  def password_initialized?
    encrypted_password_changed? && encrypted_password.present? && encrypted_password_was.blank?
  end

  def family_id
    sac_family.id
  end

  def salutation_label(key)
    prefix = 'activerecord.attributes.person.salutations'
    I18n.t("#{prefix}.#{key.presence || I18nEnums::NIL_KEY}")
  end

  def sac_family
    @sac_family ||= People::SacFamily.new(self)
  end

  def sac_family_member?
    sac_family.member?
  end

  def adult?
    birthday && years > SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.begin
  end

  def picture_profile_default
    'profile.svg' # default image for profile variant
  end

  def sac_tour_guide?
    roles.where(type: SacCas::TOUR_GUIDE_ROLES).exists?
  end

  private

  def sac_membership
    @sac_membership ||= People::SacMembership.new(self)
  end

end
