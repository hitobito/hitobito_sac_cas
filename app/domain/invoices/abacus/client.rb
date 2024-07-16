# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    # See https://apihub.abacus.ch or doc/abacus.md for documentation
    # To debug requests, set `RestClient.log = 'stdout'`
    class Client
      OPENID_CONFIG_PATH = "/.well-known/openid-configuration"
      API_PATH = "/api/entity/v1/mandants/"
      BATCH_PATH = "$batch"
      RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS = 30
      BATCH_BOUNDARY = "batch-boundary"
      BATCH_TIMEOUT = 300 # 5 minutes

      include JsonCoder

      def initialize
        raise "#{Config::FILE_PATH} not found" unless config.exist?
      end

      def list(type, params = {})
        request(:get, endpoint(type), params).fetch(:value)
      end

      def get(type, id, params = {})
        request(:get, endpoint(type, id), params)
      end

      def create(type, attrs)
        request(:post, endpoint(type), attrs)
      end

      def update(type, id, attrs)
        request(:patch, endpoint(type, id), attrs)
      end

      def delete(type, id)
        request(:delete, endpoint(type, id))
      end

      def batch(&) # rubocop:disable Metrics/MethodLength
        @batch_boundary = generate_batch_boundary
        body = build_batch_body(&)
        handle_bad_request do
          response = RestClient::Request.execute(
            method: :post,
            url: url(BATCH_PATH),
            payload: body,
            headers: batch_headers,
            read_timeout: BATCH_TIMEOUT
          )
          BatchResponse.new(response)
        end
      end

      def request(method, path, params = nil)
        if in_batch?
          @batch_body << batch_request(method, path, params)
          nil
        else
          json_request(method, path, params)
        end
      end

      def endpoint(type, id = nil)
        path = type.to_s.pluralize.camelize
        path += id_segment(id) if id
        path
      end

      def in_batch?
        !@batch_body.nil?
      end

      private

      def json_request(method, path, params = nil)
        handle_bad_request do
          response = RestClient.send(method, *request_args(method, path, params))
          decode_json(response.body)
        end
      end

      def request_args(method, path, params = nil)
        [
          url(request_path(method, path, params)),
          request_body(method, params),
          headers
        ].compact
      end

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

      def headers
        {
          authorization: "Bearer #{token}",
          content_type: :json,
          accept: :json
        }
      end

      def generate_batch_boundary
        "#{BATCH_BOUNDARY}-#{SecureRandom.uuid}"
      end

      def build_batch_body
        raise "Nested batch requests are not allowed" if in_batch?

        @batch_body = +""
        yield
        @batch_body << "--#{@batch_boundary}--\r\n"
      ensure
        @batch_body = nil
      end

      def batch_request(method, path, params = nil)
        <<~HTTP
          --#{@batch_boundary}\r
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

      def batch_headers
        {
          authorization: "Bearer #{token}",
          content_type: "multipart/mixed;boundary=#{@batch_boundary}",
          accept_charset: "UTF-8"
        }
      end

      def id_segment(id)
        if id.is_a?(Hash)
          "(#{camelize_keys(id).map { |k, v| "#{k}=#{v}" }.join(",")})"
        elsif id
          "(Id=#{id})"
        end
      end

      def url(path)
        "#{config.host}#{API_PATH}#{config.mandant}/#{path}"
      end

      def handle_bad_request
        yield
      rescue RestClient::BadRequest => e
        msg = response_error_message(e)
        e.message = msg if msg.present?
        raise e
      end

      def response_error_message(exception)
        extract_json_error(exception.response.body)
      end

      def token
        if @token_expires_at.nil? || @token_expires_at <= Time.zone.now
          response = request_token
          @token = response["access_token"]
          @token_expires_at =
            Time.zone.now + response["expires_in"].to_i - RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS
        end

        @token
      end

      def request_token
        response = RestClient.post(
          token_endpoint,
          {grant_type: "client_credentials"},
          {content_type: "application/x-www-form-urlencoded",
           authorization: "Basic #{auth_credentials}"}
        )
        JSON.parse(response.body)
      end

      def auth_credentials
        Base64.strict_encode64("#{config.username}:#{config.password}")
      end

      def token_endpoint
        response = RestClient.get(config.host + OPENID_CONFIG_PATH)
        JSON.parse(response.body)["token_endpoint"]
      end

      def config
        Config
      end
    end
  end
end
