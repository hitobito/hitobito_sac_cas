module Wizards
  module Steps
    module SignupBasicLogin
      class MainPerson < WizardStep
        # partial is optional, if not set, it will be inferred from the class name
        # self.partial = 'wizards/steps/signup_basic_login/person'

        attribute :first_name, :string
        attribute :last_name, :string
        attribute :birthday, :date
        attribute :gender, :string # TODO: validate inclusion in
        attribute :address, :string
        attribute :zip_code, :string # TODO: validate format
        attribute :town, :string
        attribute :country, :string
        attribute :phone_number, :string # TODO: validate format
        attribute :statutes, :boolean
        attribute :data_protection, :boolean
        attribute :newsletter, :boolean

        validates_presence_of :first_name, :last_name, :birthday, :statutes, :data_protection

        def salutation_label(key)
          ::Person.new.salutation_label(key)
        end

        def link_translations(key)
          ["link_#{key}_title", "link_#{key}"].map do |str|
            I18n.t(str, scope: 'self_registration.infos_component')
          end
        end
      end
    end
  end
end
