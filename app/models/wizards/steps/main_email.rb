module Wizards
  module Steps
    class MainEmail < WizardStep
      include ValidatedEmail

      attribute :email, :string
      validates :email, presence: true

      validate :ensure_email_available

      # #email_changed? is used in `ValidatedEmail` to determine if the email should be validated.
      # Here it should only be validated if the email is present.
      def email_changed?
        email.present?
      end
      
      def ensure_email_available
        unless Person.where(email: email).none?
          errors.add(:email, I18n.t('activerecord.errors.models.person.attributes.email.taken'))
        end
      end
    end
  end
end
