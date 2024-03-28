# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Invoice
  module Abacus
    # See https://apihub.abacus.ch/general for documentation
    class Client

      OPENID_CONFIG_PATH = '/.well-known/openid-configuration'
      API_PATH = '/api/entity/v1/mandants/'
      RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS = 30

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

      private

      def request(method, path, params = nil)
        response = RestClient.send(method, *request_args(method, path, params))
        decode_json(response.body)
      end

      def request_args(method, path, params = nil)
        args = [path]
        args << encode_json(params) if params && method != :get
        args << (params && method == :get ? headers.merge(params: params) : headers)
        args
      end

      def headers
        {
          authorization: "Bearer #{token}",
          content_type: :json,
          accept: :json
        }
      end

      def endpoint(type, id = nil)
        path = type.to_s.pluralize.camelize
        path += "(Id=#{id})" if id
        url(path)
      end

      def url(path)
        "#{config.host}#{API_PATH}#{config.mandant}/#{path}"
      end

      def encode_json(attrs)
        attrs.deep_transform_keys { |key| key.to_s.camelize }.to_json
      end

      def decode_json(json)
        JSON.parse(json).deep_transform_keys { |key| key.underscore.to_sym }
      end

      def token
        if @token_expires_at.nil? || @token_expires_at <= Time.zone.now
          response = request_token
          @token = response['access_token']
          @token_expires_at =
            Time.zone.now + response['expires_in'].to_i - RENEW_TOKEN_BEFORE_EXPIRATION_SECONDS
        end

        @token
      end

      def request_token
        response = RestClient.post(
          token_endpoint,
          { grant_type: 'client_credentials' },
          { content_type: 'application/x-www-form-urlencoded',
            authorization: "Basic #{auth_credentials}" }
        )
        JSON.parse(response.body)
      end

      def auth_credentials
        Base64.strict_encode64("#{config.username}:#{config.password}")
      end

      def token_endpoint
        response = RestClient.get(config.host + OPENID_CONFIG_PATH)
        JSON.parse(response.body)['token_endpoint']
      end

      def config
        Settings.invoice.abacus
      end

    end
  end
end
