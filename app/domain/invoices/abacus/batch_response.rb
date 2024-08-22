# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class BatchResponse
      class Part
        include JsonCoder

        attr_reader :response, :request

        delegate :context_object, to: :request

        def initialize(response, request)
          @response = response
          @request = request
        end

        def success?
          status >= 200 && status < 300
        end

        def created?
          status == 201
        end

        def status
          @status ||= response.code.to_i
        end

        def json
          decode_json(response.body)
        end

        def error
          return if success?

          extract_json_error(response.body)
        end

        def error_payload
          return if success?

          payload = {request: request.to_h, status: status}
          message = error
          if message.present?
            payload.merge(message: message)
          else
            payload.merge(response_body: response.body)
          end
        end
      end

      BLANK_LINE = "\r\n\r\n"

      attr_reader :response, :request_parts

      def initialize(response, request_parts)
        @response = response
        @request_parts = request_parts
      end

      def parts
        @parts ||= extract_parts
      end

      private

      def extract_parts
        body_parts = split_body_into_parts
        assert_parts_size(body_parts.size)
        body_parts.map.with_index do |part, index|
          Part.new(parse_http_part(part), request_parts[index])
        end
      end

      def assert_parts_size(size)
        if size != request_parts.size
          raise rest_exception("Batch response does not contain expected number of parts")
        end
      end

      def split_body_into_parts
        response.body.split("--#{boundary}")[1..-2] || []
      end

      def parse_http_part(part)
        http = part.split(BLANK_LINE, 2).last
        io = Net::BufferedIO.new(StringIO.new(http))
        res = Net::HTTPResponse.read_new(io)
        res.reading_body(io, true) { yield res if block_given? }
        res
      end

      def boundary
        @boundary ||= parse_boundary
      end

      def parse_boundary
        content_type = response.headers[:content_type].to_s
        content_type[/\Amultipart\/.*boundary="?([^\";,]+)"?/, 1] ||
          raise(rest_exception("Could not parse multipart boundary from content type header"))
      end

      def rest_exception(message)
        RestClient::Exception.new(response).tap do |ex|
          ex.message = message
        end
      end
    end
  end
end
