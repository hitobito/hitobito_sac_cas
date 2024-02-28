# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::SelfRegistration
  extend ActiveSupport::Concern

  prepended do
    delegate :email, to: :main_person

    class_attribute :shared_partial

    def self.for(group)
      case group
      when Group::AboBasicLogin
        SelfRegistration::AboBasicLogin
      when Group::AboMagazin
        SelfRegistration::AboMagazin
      when Group::AboTourenPortal
        SelfRegistration::AboTourenPortal
      when Group::SektionsNeuanmeldungenNv, Group::SektionsNeuanmeldungenSektion
        SelfRegistrationNeuanmeldung
      else
        SelfRegistration
      end
    end
  end

  def redirect_to_login?
    first_step? && existing_valid_email?
  end

  private

  def existing_valid_email?
    ::Person.where(email: email).exists? &&
      Truemail.validate(email.to_s, with: :regex).result.success
  end
end
