#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    class TerminationChooseDate < Wizards::Step
      TERMINATE_ON_OPTIONS = %w[now end_of_year].freeze
      attribute :terminate_on, :string

      validates :terminate_on, presence: true, inclusion: {in: TERMINATE_ON_OPTIONS}

      def terminate_on_options
        TERMINATE_ON_OPTIONS.map do |option|
          [option, self.class.human_attribute_name(option, year: Date.current.year)]
        end
      end
    end
  end
end
