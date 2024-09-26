# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup
  module AgreementFields
    extend ActiveSupport::Concern

    AGREEMENTS = [
      :statutes,
      :data_protection
    ].freeze

    included do
      include Rails.application.routes.url_helpers

      AGREEMENTS.each do |agreement|
        attribute agreement, :boolean, default: false
        validates agreement, acceptance: true
      end

      attribute :newsletter, :boolean
    end

    def link_translations(key)
      ["link_#{key}_title", "link_#{key}"].map do |str|
        I18n.t(str, scope: "self_registration.infos_component")
      end
    end
  end
end
