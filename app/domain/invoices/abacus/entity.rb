# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Invoices
  module Abacus
    class Entity
      attr_writer :client

      attr_reader :entity, :errors

      def initialize(entity, client: nil)
        @entity = entity
        @client = client
        @errors = {}
      end

      # Returns false if the entity is invalid for abacus
      def valid?
        @errors = {}
        validate
        @errors.blank?
      end

      def validate
        # implement in subclass
      end

      def client
        @client ||= ::Invoices::Abacus::Client.new
      end
    end
  end
end
