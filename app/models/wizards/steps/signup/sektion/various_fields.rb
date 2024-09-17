# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::Sektion
  class VariousFields < Wizards::Step
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

    validates :contribution_regulations, acceptance: true

    delegate :requires_adult_consent?, to: :wizard

    def self_registration_reason_options
      SelfRegistrationReason.includes(:translations).order(:created_at).collect do |r|
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

    def current_date_entry_reductions
      with_reduction_info do |date_from, date_to, discount, index|
        I18n.t("period_info_#{index}", scope: "wizards.steps.signup.sektion.various_fields", date_to:, date_from:, discount:)
      end
    end

    private

    def with_reduction_info
      [nil, :discount_date_1, :discount_date_2, :discount_date_3].each_cons(2).each.with_index(1) do |(from_date_key, to_date_key), index|
        from, formatted_from = formatted_date(from_date_key) if from_date_key
        to, formatted_to = formatted_date(to_date_key, subtract_one_day: true)
        discount = SacMembershipConfig.last.discount_percent(to) unless to.nil?
        return yield(formatted_from, formatted_to, discount, index) if (from..to).cover?(today)
      end
    end

    def formatted_date(date_key, subtract_one_day: false)
      date = date_from_string(SacMembershipConfig.last.public_send(date_key))
      if date.present?
        date = subtract_one_day ? date - 1.day : date
        [date, I18n.l(date, format: "%d.%B")]
      end
    end

    def date_from_string(date_string)
      day, month = date_string.to_s.split(".").map(&:to_i)
      Date.new(today.year, month, day) if date_string.present?
    end

    def today
      @today ||= Time.zone.today
    end

    def privacy_policy
      @privacy_policy ||= wizard.group.layer_group.privacy_policy
    end
  end
end
