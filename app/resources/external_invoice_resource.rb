# frozen_string_literal: true

#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class ExternalInvoiceResource < ApplicationResource
  primary_endpoint "external_invoices", [:index, :show, :update]

  with_options writable: false do
    attribute :id, :integer_id
    attribute :abacus_sales_order_key, :integer
    attribute :issued_at, :date
    attribute :link_type, :string
    attribute :year, :integer
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
    attribute :link_id, :integer_id
    attribute :person_id, :integer_id
  end

  with_options writable: true do
    attribute :sent_at, :date
    attribute :state, :string
    attribute :total, :float
  end

  def base_scope
    ExternalInvoice.list
  end

  def index_ability
    JsonApi::ExternalInvoiceAbility.new(current_ability)
  end
end
