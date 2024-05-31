module Wizards
  module Steps
    module MembershipOnboarding
      class Household < WizardStep
        MAX_ADULT_COUNT = SacCas::Role::MitgliedFamilyValidations::MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT

        class Housemate
          include ActiveModel::Model
          include ActiveModel::Attributes
          include ActiveModel::Validations
          include ValidatedEmail

          attribute :household_emails
          attribute :first_name, :string
          attribute :last_name, :string
          attribute :email, :string
          attribute :birthday, :date
          attribute :gender, :string # TODO: validate inclusion in
          attribute :number, :string # TODO: validate format
          attribute :_destroy, :boolean

          validates_presence_of :first_name, :last_name, :email, :birthday
          validate :ensure_family_age
          validate :ensure_email_unique_in_household

          # #email_changed? is used in `ValidatedEmail` to determine if the email should be validated.
          # Here it should only be validated if the email is present.
          def email_changed?
            email.present?
          end

          def adult?
            SacCas::Beitragskategorie::Calculator.new(Person.new(birthday: birthday)).adult?
          end

          def gender_label(...)
            Person.new(gender: gender).gender_label(...)
          end

          def ensure_email_available
            unless Person.where(email: email).none? && household_emails.to_a.count(email) <= 1
              errors.add(:email, I18n.t('activerecord.errors.models.person.attributes.email.taken'))
            end
          end

          def ensure_email_unique_in_household
            return unless household_emails.to_a.count(email) > 1

            errors.add(:email, :taken)
          end

          def ensure_family_age
            calculator = SacCas::Beitragskategorie::Calculator.new(person)
            return if calculator.family_age? # everyting in order, no need to check further

            errors.add(:birthday, :too_young_for_family) if calculator.pre_school_child?
            errors.add(:birthday, :youth_not_allowed_in_family) if calculator.youth?
          end

        end

        def initialize(registration, group:, person:, params:)
          super
          self.housemates = build_housemates(params)
        end

        attribute :housemates, array: true, default: []

        validate :ensure_valid_adult_count

        def housemates_attributes=(params)
          binding.pry
        end

        def build_housemates(params)
          params.fetch(:housemates, []).map do |housemate_params|
            Housemate.new(household_emails: household_emails, **housemate_params)
          end
        end

        def valid?(context = nil)
          super && housemates.all?(&:valid?)
        end

        def empty?
          housemates.empty?
        end

        def main_person_email
          registration.main_person.email
        end

        def household_emails
          housemates.map(&:email) << main_person_email
        end

        def adult_housemates
          housemates.select(&:adult?)
        end

        def ensure_valid_adult_count
          adults = adult_housemates
          # The main person is adult, so housemates can have 1 adult less than the maximum.
          return if adults.size < MAX_ADULT_COUNT

          adults.each { |adult| adult.errors.add(:base, too_many_adults_message) }
        end

        def too_many_adults_message
          I18n.t('activerecord.errors.messages.too_many_adults_in_family', max_adults: MAX_ADULT_COUNT)
        end

        # Workaround to get nested_form to work with active model Household
        def self.reflect_on_association(association)
          raise 'unexpected association' unless association == :housemates

          OpenStruct.new(klass: Housemate)
        end

      end
    end
  end
end
