# frozen_string_literal: true

#  Copyright (c) 2023-2025, Schweizer Alpen-Club. This file is part of
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

    delegate :newsletter, to: :person_fields

    self.asides = ["aside_abo_basic_login"]

    def member_or_applied?
      current_user&.roles.present? # do not allow if person already has an active role
    end

    def redirection_message = I18n.t("groups.self_registration.create.can_login_already_notice")

    def save!
      if current_user
        person.save!
      else
        super
      end

      mailing_list&.subscribe_if(person, newsletter)
    end

    private

    def build_person
      super do |person, role|
        person.gender = nil if person.gender == I18nEnums::NIL_KEY

        yield person, role if block_given?
      end
    end

    def person_attributes
      person_fields.person_attributes.merge(email:)
    end

    def step_after(step_class_or_name)
      if step_class_or_name == :_start && current_user
        Wizards::Steps::Signup::AboBasicLogin::PersonFields.step_name
      else
        super
      end
    end

    def mailing_list = MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
  end
end
