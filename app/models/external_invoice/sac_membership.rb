# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: external_invoices
#
#  id                     :bigint           not null, primary key
#  abacus_sales_order_key :integer
#  issued_at              :date
#  link_type              :string(255)
#  sent_at                :date
#  state                  :string(255)      default("draft"), not null
#  total                  :decimal(12, 2)   default(0.0), not null
#  type                   :string(255)      not null
#  year                   :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  link_id                :bigint
#  person_id              :bigint           not null
#
# Indexes
#
#  index_external_invoices_on_link       (link_type,link_id)
#  index_external_invoices_on_person_id  (person_id)
#
class ExternalInvoice::SacMembership < ExternalInvoice
  # link is currently a Group::Section or Group::Ortsgruppe object
  # this is not definitively defined yet, it might become a Role object as well
  # depending on the requirements for updating roles once an invoice is payed.

  after_update :handle_state_change_to_payed

  def title
    I18n.t("invoices.sac_memberships.title", year: year)
  end

  private

  def handle_state_change_to_payed
    if state_changed_to_payed?
      People::ExternalInvoicePayedJob.new(person, link, year).enqueue!
    end
  end

  def state_changed_to_payed?
    saved_change_to_state? && state == "payed"
  end
end
