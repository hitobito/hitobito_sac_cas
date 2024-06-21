# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    class ChooseMembership < Step
      OPTIONS = %w[myself family].freeze

      attribute :register_as, :string, default: "myself"
      validates :register_as, inclusion: {in: %w[myself family]}
      validates :register_as, presence: true

      def register_as_options
        OPTIONS.map do |option|
          [option, self.class.human_attribute_name(option)]
        end
      end

      def register_as_family?
        register_as == "family"
      end

      def main_person
        wizard.person.household.main_person
      end

      def sac_family_main_person?
        @wizard.person.sac_family_main_person
      end
    end
  end
end
