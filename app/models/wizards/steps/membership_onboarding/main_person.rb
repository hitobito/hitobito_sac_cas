module Wizards
  module Steps
    module MembershipOnboarding
      class MainPerson < WizardStep
        attribute :first_name, :string
        attribute :last_name, :string
        attribute :birthday, :date
        attribute :gender, :string # TODO: validate inclusion in
        attribute :address, :string
        attribute :zip_code, :string # TODO: validate format
        attribute :town, :string
        attribute :country, :string, default: Settings.addresses.imported_countries.to_a.first
        attribute :phone_number, :string # TODO: validate format
        attribute :statutes, :boolean
        attribute :data_protection, :boolean
        attribute :newsletter, :boolean

        validates_presence_of :first_name, :last_name, :birthday, :address, :zip_code, :town, :country, :phone_number
        # validate :assert_valid_phone_number # TODO: reimplement

        def salutation_label(key)
          ::Person.new.salutation_label(key)
        end

        def link_translations(key)
          ["link_#{key}_title", "link_#{key}"].map do |str|
            I18n.t(str, scope: 'self_registration.infos_component')
          end
        end

        def adult?
          BeitragsKategorie::Calculator.new(Person.new(birthday: birthday)).adult?
        end
      end
    end
  end
end
