# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Signup
  class AboBasicLoginWizard < Wizards::RegisterNewUserWizard
    self.steps = [
      Wizards::Steps::Signup::MainEmailField,
      Wizards::Steps::Signup::AboBasicLogin::PersonFields
    ]

    public :group

    delegate :email, to: :main_email_field
    delegate :newsletter, to: :person_fields

    self.asides = ["aside_abo_basic_login"]

    def save!
      if current_user.present?
        person.save!
      else
        super
      end

      mailing_list&.subscribe_if(person, newsletter)
    end

    private

    def build_person
      if current_user.present?
        current_user.tap do |person|
          person.roles.build(group: group, type: group.self_registration_role_type)
        end
      else
        super do |_person, role|
          role.end_on = Date.current.end_of_year
        end
      end
    end

    def person_attributes
      person_fields
        .person_attributes
        .merge(main_email_field.attributes)
    end

    def step_after(step_class_or_name)
      case step_class_or_name
      when :_start
        handle_start
      else
        super
      end
    end

    def handle_start
      if current_user.present?
        Wizards::Steps::Signup::AboBasicLogin::PersonFields.step_name
      else
        Wizards::Steps::Signup::MainEmailField.step_name
      end
    end

    def mailing_list = MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
  end
end
