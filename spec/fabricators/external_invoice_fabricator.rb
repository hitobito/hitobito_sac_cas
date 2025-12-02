# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# spec/fabricators/external_invoice_fabricator.rb

Fabricator(:external_invoice) do
  type "ExternalInvoice"
  person { Fabricate(:person) }
  state { "open" }
  issued_at { Date.parse("2024-07-26") }
  sent_at { Date.parse("2024-07-26") }
  total { rand(1..100).to_f }
  link_type nil
  link_id nil
  year 2024
  abacus_sales_order_key { sequence(:abacus_sales_order_key) { |i| 123123 + i } }
  created_at { DateTime.parse("2024-07-26T14:41:08.713027+02:00") }
  updated_at { DateTime.parse("2024-08-01T17:43:55.822004+02:00") }
end

Fabricator(:sac_membership_invoice, from: :external_invoice) do
  type "ExternalInvoice::SacMembership"
end

Fabricator(:abo_magazin_invoice, from: :external_invoice) do
  type "ExternalInvoice::AboMagazin"
end
