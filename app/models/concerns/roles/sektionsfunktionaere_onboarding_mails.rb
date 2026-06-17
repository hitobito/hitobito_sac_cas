# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Roles::SektionsfunktionaereOnboardingMails
  extend ActiveSupport::Concern

  included do
    attr_accessor :send_onboarding_mail
    after_save :deliver_onboarding_mail, if: :send_onboarding_mail
  end

  private

  def deliver_onboarding_mail
    method_name = :"#{self.class.name.demodulize.underscore}_onboarding"
    People::SektionsfunktionaereMailer.send(method_name, self).deliver_later
  end
end
