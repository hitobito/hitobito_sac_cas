# frozen_string_literal: true

#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class ExternalInvoiceResource < ApplicationResource
  primary_endpoint "external_invoices", [:index, :show, :update]

  belongs_to :person, resource: PersonResource

  with_options writable: false, filterable: true, sortable: true do
    attribute :id, :integer_id
    attribute :person_id, :integer_id
    attribute :type, :string
    attribute :link_type, :string
    attribute :link_id, :integer_id
    attribute :issued_at, :date
    attribute :year, :integer
    attribute :abacus_sales_order_key, :integer
  end

  with_options writable: true, filterable: true, sortable: true do
    attribute :state, :string
  end

  with_options writable: true, filterable: false, sortable: false do
    attribute :sent_at, :date
    attribute :total, :float
  end

  with_options writable: false, filterable: false, sortable: false do
    attribute :created_at, :datetime
    attribute :updated_at, :datetime
  end

  def index_ability
    return current_ability if current_ability.is_a?(TokenAbility)

    # Necessary because ExternalInvoiceAbility does not give us accessible_by
    JsonApi::ExternalInvoiceAbility.new(current_ability.user_context.user)
  end
end
