# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TTY
  module Command
    extend ActiveSupport::Concern

    prepended do
      include TTY::Helpers::Format
      extend TTY::Helpers::Format
      include TTY::Helpers::PaperTrailed

      class_attribute :description
    end

    def initialize
      puts light_yellow description
      super
    end

    def run
      set_papertrail_metadata
      super
    end

    class_methods do
      def [](key)
        case key
        when :description then description
        when :action then -> { new.run }
        end
      end

      def deconstruct
        [description, new]
      end

      def deconstruct_keys(*keys)
        {description:, action: -> { new.run }}
      end
    end
  end
end
