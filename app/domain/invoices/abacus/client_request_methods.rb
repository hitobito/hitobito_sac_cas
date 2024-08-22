# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    module ClientRequestMethods
      private

      def request_body(method, params)
        encode_json(params) if params && method != :get
      end

      def request_path(method, path, params)
        if params && method == :get
          "#{path}?#{RestClient::Utils.encode_query_string(params)}"
        else
          path
        end
      end
    end
  end
end
