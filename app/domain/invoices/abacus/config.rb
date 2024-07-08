# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class Config
      FILE_PATH = HitobitoSacCas::Wagon.root.join("config", "abacus.yml")
      KEYS = %w[host mandant username password].freeze

      class << self
        def exist?
          config.present?
        end

        KEYS.each do |key|
          define_method(key) do
            config[key]
          end
        end

        private

        def config
          return @config if defined?(@config)

          @config = load.freeze
        end

        def load
          return nil unless File.exist?(FILE_PATH)

          YAML.safe_load_file(FILE_PATH)&.fetch("abacus", nil)
        end
      end
    end
  end
end
