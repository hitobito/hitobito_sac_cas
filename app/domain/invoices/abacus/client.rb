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
      include ClientRequestMethods

      def initialize
        raise "#{Config::FILE_PATH} not found" unless config.exist?
        @token_semaphore = Thread::Mutex.new
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
        self.batch_context_object = nil
        request_parts = record_batch_request_parts(&)
        return [] if request_parts.blank?

        handle_bad_request do
          boundary = generate_batch_boundary
          response = RestClient::Request.execute(
            method: :post,
            url: url(BATCH_PATH),
            payload: build_batch_body(request_parts, boundary),
            headers: batch_headers(boundary),
            read_timeout: BATCH_TIMEOUT
          )
          BatchResponse.new(response, request_parts).parts
        end
      end

      def request(method, path, params = nil)
        if in_batch?
          thread_local_get(:batch_request_parts) << BatchRequestPart.new(method, path, params, batch_context_object)
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
        !thread_local_get(:batch_request_parts).nil?
      end

      def batch_context_object
        thread_local_get(:batch_context_object)
      end

      def batch_context_object=(object)
        thread_local_set(:batch_context_object, object)
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

      def record_batch_request_parts
        raise "Nested batch requests are not allowed" if in_batch?

        thread_local_set(:batch_request_parts, [])
        yield
        thread_local_get(:batch_request_parts)
      ensure
        thread_local_set(:batch_request_parts, nil)
      end

      def build_batch_body(request_parts, boundary)
        boundary_line = "--#{boundary}\r\n"
        "#{boundary_line}#{request_parts.map(&:body).join(boundary_line)}--#{boundary}--\r\n"
      end

      def batch_headers(boundary)
        {
          authorization: "Bearer #{token}",
          content_type: "multipart/mixed;boundary=#{boundary}",
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
        @token_semaphore.synchronize { renew_expired_token }
        @token
      end

      def renew_expired_token
        return if @token_expires_at.present? && @token_expires_at > Time.zone.now

        response = request_token
        @token = response["access_token"]
        @token_expires_at =
          Time.zone.now + response["expires_in"].to_i - RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS
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

      def thread_local_get(key)
        Thread.current[thread_local_key(key)]
      end

      def thread_local_set(key, object)
        Thread.current[thread_local_key(key)] = object
      end

      def thread_local_key(key)
        "abacus_client_#{object_id}_#{key}"
      end
    end
  end
end
