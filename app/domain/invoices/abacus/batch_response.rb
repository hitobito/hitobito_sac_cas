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

        attr_reader :response

        def initialize(response)
          @response = response
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
      end

      BLANK_LINE = "\r\n\r\n"

      attr_reader :response

      def initialize(response)
        @response = response
      end

      def parts
        @parts ||= extract_parts.map { |part| parse_http_part(part) }
      end

      private

      def extract_parts
        response.body.split("--#{boundary}")[1..-2]
      end

      def parse_http_part(part)
        http = part.split(BLANK_LINE, 2).last
        io = Net::BufferedIO.new(StringIO.new(http))
        res = Net::HTTPResponse.read_new(io)
        res.reading_body(io, true) { yield res if block_given? }
        Part.new(res)
      end

      def boundary
        @boundary ||= parse_boundary
      end

      def parse_boundary
        content_type = response.headers[:content_type].to_s
        content_type[/\Amultipart\/.*boundary="?([^\";,]+)"?/, 1] ||
          raise(ArgumentError, "Could not parse multipart boundary from content type header")
      end
    end
  end
end
