# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class SelfRegistrationReasonColumn < TableDisplays::Column
    def required_model_attrs(attr)
      [:self_registration_reason_id]
    end

    def render(attr)
      super do |person|
        self_registration_reason(person)
      end
    end

    def required_permission(attr)
      :show_full
    end

    private

    def allowed_value_for(target, target_attr, &block)
      self_registration_reason(target)
    end

    def self_registration_reason(person)
      person.self_registration_reason&.text
    end
  end
end
