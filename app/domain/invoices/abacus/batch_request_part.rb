# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class BatchRequestPart
      include JsonCoder
      include ClientRequestMethods

      attr_reader :method, :path, :params, :context_object

      def initialize(method, path, params = nil, context_object = nil)
        @method = method
        @path = path
        @params = params
        @context_object = context_object
      end

      def to_h
        {
          method: method,
          path: path,
          params: params
        }
      end

      def body
        <<~HTTP
          Content-Type: application/http\r
          Content-Transfer-Encoding: binary\r
          \r
          #{method.to_s.upcase} #{request_path(method, path, params)} HTTP/1.1\r
          Content-Type: application/json\r
          Accept: application/json\r
          \r
          #{request_body(method, params)}\r
        HTTP
      end
    end
  end
end
