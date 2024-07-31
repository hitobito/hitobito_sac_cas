# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::Sektion
  class VariousFields < Wizards::Step
    include FutureRole::FormHandling
    include Wizards::Steps::Signup::AgreementFields

    DYNAMIC_AGREEMENTS = [
      :sektion_statuten,
      :adult_consent
    ].freeze

    DYNAMIC_AGREEMENTS.each do |agreement|
      attribute agreement, :boolean
      validates agreement, acceptance: true, if: :"requires_#{agreement}?"
    end

    attribute :contribution_regulations, :boolean, default: false
    attribute :self_registration_reason_id, :integer
    attribute :register_on, :string, default: :now

    validates :contribution_regulations, acceptance: true
    validates :register_on, presence: true

    delegate :requires_adult_consent?, to: :wizard

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
