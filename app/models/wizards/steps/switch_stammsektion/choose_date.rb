# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    module SwitchStammsektion
      class ChooseDate < Step
        SWITCH_ON_OPTIONS = %w[now next_year].freeze
        attribute :switch_on, :string

        validates :switch_on, presence: true
        validates :switch_on, inclusion: {in: SWITCH_ON_OPTIONS}, allow_blank: true

        delegate :human_attribute_name, to: :class

        def switch_on_options
          SWITCH_ON_OPTIONS.map do |option|
            [option, human_attribute_name(option)]
          end
        end

        def switch_on_text
          if switch_now?
            human_attribute_name(:now)
          else
            I18n.l(next_year, format: "%d. %B")
          end
        end

        def switch_date
          switch_now? ? now : next_year
        end

        private

        def now
          Time.zone.today
        end

        def next_year
          Time.zone.now.beginning_of_year.next_year.to_date
        end

        def switch_now?
          /now/.match?(switch_on)
        end
      end
    end
  end
end
