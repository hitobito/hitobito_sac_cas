module Wizards
  class MembershipOnboarding < RegistrationWizardBase
    self.steps = [
      Steps::MainEmail,
      Steps::MembershipOnboarding::MainPerson,
      Steps::MembershipOnboarding::Household,
      Steps::MembershipOnboarding::Supplements
    ]

    def step_after(step_class_or_name)
      case step_class_or_name
      when :start
        person.persisted? ? :main_email : :household
      when :main_person
        step(:main_person).adult? ? :household : :supplements
      else
        super
      end
    end

    def assign_person_attributes # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return if person.persisted?

      self.person = Person.new(
        first_name: step(:main_person).first_name,
        last_name: step(:main_person).last_name,
        email: step(:main_email).email,
        birthday: step(:main_person).birthday,
        gender: step(:main_person).gender,
        address: step(:main_person).address,
        zip_code: step(:main_person).zip_code,
        town: step(:main_person).town,
        country: step(:main_person). country,
        primary_group: group
      )
      self.person.phone_numbers.build(label: 'Mobil', number: step(:main_person).phone_number)
    end

    def save!
      ::Person.transaction do
        super

        unless person.persisted?
          person.save!
          enqueue_duplicate_locator_job(person)
        end

        raise 'TODO: implement missing parts of save!'
        # TODO: build_role.save!
        # TODO: household.save!
        # TODO: make sure `SacFamily#update!` is called (should happen when saving Household)
      end
    end

    def household
      step(:household)
    end

    def birthdays
      household.housemates.collect(&:birthday).unshift(step(:main_person).birthday).compact.shuffle
    end
  end
end
