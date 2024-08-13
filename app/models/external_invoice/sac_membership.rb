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

  def build_membership_invoice(discount, new_entry, reference_date)
    @date = reference_date
    membership_invoice = membership_invoice(discount, new_entry, reference_date)

    if !membership_invoice.invoice?
      I18n.t(".people.membership_invoices.no_invoice_possible")
    elsif memberships.blank?
      I18n.t(".people.membership_invoices.no_invoice_possible")
    else
      membership_invoice
    end
  end

  private

  def handle_state_change_to_payed
    if state_changed_to_payed?
      Invoices::SacMemberships::InvoicePayedJob.new(person.id, link.id, year).enqueue!
    end
  end

  def state_changed_to_payed?
    saved_change_to_state? && state == "payed"
  end

  def membership_invoice(discount, new_entry, reference_date)
    @membership_invoice ||= Invoices::Abacus::MembershipInvoice.new(
      member,
      memberships,
      new_entry: new_entry,
      discount: discount
    )
  end

  def memberships
    @memberships ||= if stammsektion?
      active_memberships
    elsif neuanmeldung_stammsektion?
      neuanmeldung_stammsektion_memberships
    elsif zusatzsektion?
      zusatzsektion_memberships
    else
      []
    end
  end

  def active_memberships
    [member.membership_from_role(sac_member.stammsektion_role)] +
      sac_member.zusatzsektion_roles.map { |r| member.membership_from_role(r) }
  end

  def neuanmeldung_stammsektion_memberships
    [member.membership_from_role(sac_member.neuanmeldung_stammsektion_role, main: true)]
  end

  def zusatzsektion_memberships
    (sac_member.zusatzsektion_roles + sac_member.neuanmeldung_zusatzsektion_roles)
      .select { |role| role.layer_group == link.layer_group }
      .map { |r| member.membership_from_role(r) }
  end

  def handle_invoice_generation_error(message)
    update!(state: :error)
    HitobitoLogEntry.create!(
      message: message,
      level: :error,
      category: "rechnungen",
      subject: @invoice
    )
  end

  def stammsektion? = link.layer_group == sac_member.stammsektion_role&.layer_group

  def neuanmeldung_stammsektion? = link.layer_group == sac_member.neuanmeldung_stammsektion_role&.layer_group

  def zusatzsektion? = (sac_member.zusatzsektion_roles + sac_member.neuanmeldung_zusatzsektion_roles).map(&:layer_group).include?(link.layer_group)

  def sac_member = @sac_member ||= People::SacMembership.new(person_with_membership_years, date: @date)

  def member = @member ||= Invoices::SacMemberships::Member.new(person_with_membership_years, context)

  def context = @context ||= Invoices::SacMemberships::Context.new(@date)

  def person_with_membership_years = @person ||= Person.with_membership_years("people.*", @date.beginning_of_year).find(person.id)
end
