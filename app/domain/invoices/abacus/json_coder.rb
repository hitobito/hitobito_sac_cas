# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    module JsonCoder
      private

      def encode_json(attrs)
        camelize_keys(attrs).to_json
      end

      def decode_json(json)
        return {} if json.blank?

        underscore_keys(JSON.parse(json))
      end

      def camelize_keys(hash)
        hash.deep_transform_keys { |key| key.to_s.camelize }
      end

      def underscore_keys(hash)
        hash.deep_transform_keys { |key| key.underscore.to_sym }
      end

      def extract_json_error(body)
        decode_json(body).dig(:error, :message)
      rescue # do not fail if response is not JSON
        nil
      end
    end
  end
end
