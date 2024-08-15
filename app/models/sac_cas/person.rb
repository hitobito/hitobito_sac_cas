# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Person
  extend ActiveSupport::Concern

  CORRESPONDENCES = %w[digital print]
  DATA_QUALITIES = %w[ok info warning error]

  included do
    Person::SAC_REMARK_NATIONAL_OFFICE = "sac_remark_national_office"
    Person::SAC_SECTION_REMARKS = %w[sac_remark_section_1 sac_remark_section_2 sac_remark_section_3
      sac_remark_section_4 sac_remark_section_5]
    Person::SAC_REMARKS = Person::SAC_SECTION_REMARKS + [Person::SAC_REMARK_NATIONAL_OFFICE]

    Person::INTERNAL_ATTRS.concat(Person::SAC_REMARKS.map(&:to_sym))
    Person::LANGUAGES.delete(:en)

    paper_trail_options[:skip] += Person::SAC_REMARKS
    devise_login_id_attrs << :membership_number

    Person.used_attributes.delete(:nickname)

    delegate :active?, :anytime?, :invoice?, :family?, :stammsektion_role,
      to: :sac_membership, prefix: true
    delegate :family_id, to: :sac_membership

    alias_attribute :membership_number, :id
    alias_attribute :navision_id, :id

    i18n_enum :correspondence, CORRESPONDENCES
    i18n_setter :correspondence, CORRESPONDENCES

    enum data_quality: {ok: 0, info: 1, warning: 2, error: 3}, _default: 0

    reflect_on_attachment(:picture).variant(:profile, resize_to_fill: [200, 200])

    has_many :data_quality_issues, dependent: :destroy
    has_many :external_invoices, dependent: :destroy
    has_many :external_trainings, dependent: :destroy
    has_many :roles_with_deleted, -> { with_deleted }, class_name: "Role", foreign_key: "person_id"

    validates(*Person::SAC_REMARKS, format: {with: /\A[^\n\r]*\z/})

    before_save :set_digital_correspondence, if: :password_initialized?
    after_save :check_data_quality

    delegate :salutation_label, to: :class

    scope :with_membership_years, lambda { |selects = "people.*", date = Time.zone.today|
      subquery_sql = Group::SektionsMitglieder::Mitglied
        .with_deleted
        .with_membership_years("roles.person_id", date)
        .to_sql

      select(*Array.wrap(selects), "FLOOR(SUM(COALESCE(membership_years, 0))) as membership_years")
        .joins("LEFT JOIN (#{subquery_sql}) AS subquery ON people.id = subquery.person_id")
        .group("people.id")
    }
  end

  module ClassMethods
    def salutation_label(key)
      prefix = "activerecord.attributes.person.salutations"
      I18n.t("#{prefix}.#{key.presence || I18nEnums::NIL_KEY}")
    end
  end

  def membership_years
    read_attribute(:membership_years) or raise "use Person scope :with_membership_years"
  end

  def set_digital_correspondence
    self.correspondence = "digital"
  end

  def password_initialized?
    encrypted_password_changed? && encrypted_password.present? && encrypted_password_was.blank?
  end

  def adult?(reference_date: Time.zone.today.end_of_year)
    SacCas::Beitragskategorie::Calculator.new(self, reference_date: reference_date).adult?
  end

  def picture_profile_default
    "profile.svg" # default image for profile variant
  end

  def sac_tour_guide?
    roles.exists?(type: SacCas::TOUR_GUIDE_ROLES.map(&:sti_name))
  end

  def backoffice?
    roles.exists?(type: SacCas::SAC_BACKOFFICE_ROLES.map(&:sti_name))
  end

  def sac_membership
    @sac_membership ||= People::SacMembership.new(self)
  end

  private

  def check_data_quality
    return if (People::DataQualityChecker::ATTRIBUTES_TO_CHECK & saved_changes.keys).empty?

    People::DataQualityChecker.new(self).check_data_quality
  end
end
