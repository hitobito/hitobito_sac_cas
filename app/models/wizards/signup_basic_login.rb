module Wizards
  class SignupBasicLogin < RegisterNewUserWizard
    prepend NewsletterHandling

    self.steps = [
      Steps::MainEmail,
      Steps::SignupBasicLogin::MainPerson
    ]

    def assign_person # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      self.person = Person.new(
        first_name: step(:main_person).first_name,
        last_name: step(:main_person).last_name,
        email: step(:main_email).email,
        birthday: step(:main_person).birthday,
        gender: step(:main_person).gender,
        address: step(:main_person).address,
        zip_code: step(:main_person).zip_code,
        town: step(:main_person).town,
        country: step(:main_person).country,
        primary_group: group
      )
      self.person.phone_numbers.build(label: 'Mobil', number: step(:main_person).phone_number)
    end

    def optout_newsletter? = !step(:main_person).newsletter

  end
end
