# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup
  class VariousFields < Wizards::Step
    include FutureRole::FormHandling
    include Rails.application.routes.url_helpers

    AGREEMENTS = [
      :statutes,
      :contribution_regulations,
      :data_protection
    ].freeze

    DYNAMIC_AGREEMENTS = [
      :sektion_statuten,
      :adult_consent
    ].freeze

    AGREEMENTS.each do |agreement|
      attribute agreement, :boolean, default: false
      validates agreement, acceptance: true
    end

    DYNAMIC_AGREEMENTS.each do |agreement|
      attribute agreement, :boolean
      validates agreement, acceptance: true, if: :"requires_#{agreement}?"
    end

    delegate :requires_adult_consent?, to: :wizard

    attribute :newsletter, :boolean
    attribute :register_on, :string, default: :now
    attribute :self_registration_reason_id, :integer

    validates :register_on, presence: true

    def self_registration_reason_options
      SelfRegistrationReason.order(:created_at).collect do |r|
        [r.id.to_s, r.text]
      end
    end

    def sektion_statuten_link_args
      label = I18n.t("link_sektion_statuten_title", scope: "self_registration.infos_component")
      path = rails_blob_path(privacy_policy, disposition: :attachment, only_path: true)
      [label, path]
    end

    def link_translations(key)
      ["link_#{key}_title", "link_#{key}"].map do |str|
        I18n.t(str, scope: "self_registration.infos_component")
      end
    end

    def requires_sektion_statuten?
      sektion_statuten.blank? && privacy_policy.attached?
    end

    def privacy_policy_accepted_at
      Time.zone.now if sektion_statuten
    end

    private

    def privacy_policy
      @privacy_policy ||= wizard.group.layer_group.privacy_policy
    end
  end
end
