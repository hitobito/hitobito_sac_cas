# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::Sektion
  class CornercardFields < Wizards::Step
    attribute :card_application, :boolean, default: false
    attribute :consent_given, :boolean, default: false

    validate :assert_consent_given_with_card_application

    def ordered?
      card_application && consent_given
    end

    def data_processing_url
      case I18n.locale.to_s
      when "fr"
        "https://www.cornercard.ch/downloads/documents/terms_sac_fr.pdf"
      when "it"
        "https://www.cornercard.ch/downloads/documents/terms_sac_it.pdf"
      else
        "https://www.cornercard.ch/downloads/documents/terms_sac.pdf"
      end
    end

    def agb_url
      case I18n.locale.to_s
      when "fr"
        "https://www.cornercard.ch/downloads/documents/terms_credit_pers_fr.pdf"
      when "it"
        "https://www.cornercard.ch/downloads/documents/terms_credit_pers_it.pdf"
      else
        "https://www.cornercard.ch/downloads/documents/terms_credit_pers_de.pdf"
      end
    end

    private

    def assert_consent_given_with_card_application
      return true if card_application == consent_given

      errors.add(:base, :cornercard_consent_missing)
    end
  end
end
