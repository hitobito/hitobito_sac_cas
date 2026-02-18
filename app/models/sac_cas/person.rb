# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Person
  extend ActiveSupport::Concern

  CORRESPONDENCES = %w[digital print]
  DATA_QUALITIES = %w[ok info warning error]
  REQUIRED_FIELDS_ROLES = [*SacCas::ABONNENT_MAGAZIN_ROLES, *SacCas::ABONNENT_TOUREN_PORTAL_ROLES,
    *SacCas::MITGLIED_STAMMSEKTION_ROLES].map(&:sti_name)
  PAPER_TRAIL_PASSWORD_OVERRIDE_EVENT = :password_override

  prepended do # rubocop:todo Metrics/BlockLength
    Person::SEARCHABLE_ATTRS << :id

    Person::SAC_REMARK_NATIONAL_OFFICE = "sac_remark_national_office"
    Person::SAC_SECTION_REMARKS = %w[sac_remark_section_1 sac_remark_section_2 sac_remark_section_3
      sac_remark_section_4 sac_remark_section_5]
    Person::SAC_REMARKS = Person::SAC_SECTION_REMARKS + [Person::SAC_REMARK_NATIONAL_OFFICE]

    Person::INTERNAL_ATTRS.concat(Person::SAC_REMARKS.map(&:to_sym))

    paper_trail_options[:skip] += [*Person::SAC_REMARKS, "wso2_legacy_password_hash",
      "wso2_legacy_password_salt"]
    devise_login_id_attrs << :membership_number

    Person.used_attributes.delete(:nickname)

    delegate :active?, :anytime?, :invoice?, :family?, :stammsektion_role, :terminated?,
      to: :sac_membership, prefix: true
    delegate :family_id, to: :sac_membership

    alias_attribute :membership_number, :id
    alias_attribute :navision_id, :id

    i18n_enum :correspondence, CORRESPONDENCES
    i18n_setter :correspondence, CORRESPONDENCES

    enum :data_quality, [:ok, :info, :warning, :error], default: 0, prefix: :data_quality

    reflect_on_attachment(:picture).variant(:profile, resize_to_fill: [200, 200])

    has_many :data_quality_issues, dependent: :destroy
    has_many :external_invoices, dependent: :destroy
    has_many :external_trainings, dependent: :destroy

    before_validation :reset_confirmed_at_and_correspondence, if: -> { email.blank? }

    validates(*Person::SAC_REMARKS, format: {with: /\A[^\n\r]*\z/})
    with_options if: :roles_require_name_and_address?, on: [:create, :update] do
      validates :first_name, :last_name, presence: true, unless: :company?
      validates :zip_code, :town, presence: true
      validates_with Person::AddressValidator
    end

    before_save :set_digital_correspondence

    after_save :check_data_quality
    after_save_commit :transmit_data_to_abacus

    delegate :salutation_label, to: :class

    scope :with_membership_years, lambda { |selects = arel_table[Arel.star], date = Date.current|
      roles_with_membership_years_sql = Group::SektionsMitglieder::Mitglied
        .with_inactive
        .with_membership_years("roles.person_id", date)
        .to_sql

      people_with_membership_years_sql = <<~SQL
        WITH membership_years_per_person AS (
          SELECT person_id, FLOOR(SUM(membership_years))::int AS membership_years
          FROM (
            #{roles_with_membership_years_sql}
          )
          GROUP BY person_id
        )
        SELECT people.*, COALESCE(membership_years, 0) AS membership_years
        FROM people
        LEFT JOIN membership_years_per_person ON people.id = membership_years_per_person.person_id
      SQL

      # alias the query as "people" so AR can use it instead of the original people table
      select(selects).from("(#{people_with_membership_years_sql}) AS people")
    }

    scope :where_login_matches, ->(value) {
      matching = Person.devise_login_id_attrs.reduce(Person.none) do |scope, attr|
        scope.or(Person.where(attr => value))
      end
      merge(matching)
    }

    generates_token_for(:account_completion, expires_in: 3.months)
    validate :assert_unconfirmed_email_is_valid, if: -> { unconfirmed_email.present? }

    include SacCas::People::Wso2LegacyPassword
  end

  module ClassMethods
    def salutation_label(key)
      prefix = "activerecord.attributes.person.salutations"
      I18n.t("#{prefix}.#{key.presence || I18nEnums::NIL_KEY}")
    end
  end

  def membership_years
    read_attribute(:membership_years) || cached_membership_years
  end

  def update_cached_membership_years!
    value = self[:membership_years] or raise "use Person scope :with_membership_years"
    update_column(:cached_membership_years, value)
  end

  def adult?(reference_date: Time.zone.today.end_of_year)
    SacCas::Beitragskategorie::Calculator.new(self, reference_date: reference_date).adult?
  end

  def youth?(reference_date: Time.zone.today.end_of_year)
    SacCas::Beitragskategorie::Calculator.new(self, reference_date: reference_date).youth?
  end

  # Liechtenstein is counted as not abroad, extra fees should not apply
  def living_abroad?
    !(swiss? || country.downcase == "li")
  end

  def picture_profile_default
    "profile.svg" # default image for profile variant
  end

  def sac_tour_guide?
    roles.exists?(type: SacCas::TOUR_GUIDE_ROLES.map(&:sti_name))
  end

  def backoffice?
    return @backoffice if defined?(@backoffice)

    @backoffice = roles.exists?(type: SacCas::SAC_BACKOFFICE_ROLES.map(&:sti_name)) || root?
  end

  def sac_membership
    People::SacMembership.new(self)
  end

  def login_status
    return :wso2_legacy_password if wso2_legacy_password?
    super
  end

  protected

  def after_confirmation # Devise::Models::Confirmable
    return if versions
      .where("object_changes LIKE '%correspondence:\n- digital\n- print\n%'")
      .exists?

    update(correspondence: :digital)
  end

  private

  def reset_confirmed_at_and_correspondence
    self.correspondence = "print"
    self.confirmed_at = nil
  end

  def set_digital_correspondence
    return unless confirmed_at.present? &&
      encrypted_password.present? &&
      encrypted_password_was.blank? &&
      wso2_legacy_password_hash_was.blank? &&
      !versions.exists?(event: PAPER_TRAIL_PASSWORD_OVERRIDE_EVENT)

    self.correspondence = "digital"
  end

  def check_data_quality
    return unless People::DataQualityChecker.attributes_to_check_changed?(self)

    People::DataQualityChecker.new(self).check_data_quality
  end

  def transmit_data_to_abacus
    if abacus_attributes_changed? && data_quality != "error" && abacus_transmittable?
      Invoices::Abacus::TransmitPersonJob.new(self).enqueue!
    end
  end

  def abacus_attributes_changed?
    (Invoices::Abacus::Subject::RELEVANT_ATTRIBUTES & saved_changes.keys).present?
  end

  def abacus_transmittable?
    abacus_subject_key.present? || sac_membership_invoice? || sac_membership.abonnent_magazin?
  end

  def roles_require_name_and_address?
    roles.exists?(type: REQUIRED_FIELDS_ROLES)
  end

  def assert_unconfirmed_email_is_valid
    if !Truemail.valid?(unconfirmed_email) || Person.where(email: unconfirmed_email).exists?
      errors.add(:unconfirmed_email, :invalid)
    end
  end
end
