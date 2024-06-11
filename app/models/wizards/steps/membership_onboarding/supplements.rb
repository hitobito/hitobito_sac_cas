module Wizards
  module Steps
    module MembershipOnboarding
      class Supplements < WizardStep
        include FutureRole::FormHandling

        AGREEMENTS = [
          :statutes,
          :contribution_regulations,
          :data_protection,
        ].freeze

        DYNAMIC_AGREEMENTS = [
          :sektion_statuten,
          :adult_consent
        ]

        AGREEMENTS.each do |agreement|
          attribute agreement, :boolean
          validates agreement, acceptance: true
        end

        DYNAMIC_AGREEMENTS.each do |agreement|
          attribute agreement, :boolean
          validates agreement, acceptance: true, if: :"requires_#{agreement}?"
        end

        attribute :newsletter, :boolean
        attribute :register_on, :string, default: :now
        attribute :self_registration_reason_id, :integer, default: :first_self_registration_reason_id

        validates :register_on, presence: true

        def self_registration_reason_options
          SelfRegistrationReason.order(:created_at).collect do |r|
            [r.id.to_s, r.text]
          end
        end

        def sektion_statuten_link_args
          label = I18n.t('link_sektion_statuten_title', scope: 'self_registration.infos_component')
          path = rails_blob_path(privacy_policy, disposition: :attachment, only_path: true)
          [label, path]
        end

        def link_translations(key)
          ["link_#{key}_title", "link_#{key}"].map do |str|
            I18n.t(str, scope: 'self_registration.infos_component')
          end
        end

        def requires_sektion_statuten?
          sektion_statuten.blank? && privacy_policy.attached?
        end

        def requires_adult_consent?
          @group.self_registration_require_adult_consent?
        end

        private

        def first_self_registration_reason_id
          SelfRegistrationReason.first&.id
        end

        def privacy_policy
          @group.layer_group.privacy_policy
        end
      end
    end
  end
end
