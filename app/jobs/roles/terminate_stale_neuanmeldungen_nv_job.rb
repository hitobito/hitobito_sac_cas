# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Roles::TerminateStaleNeuanmeldungenNvJob < RecurringJob
  run_every 1.day

  ROLE_TYPES = SacCas::NEUANMELDUNG_NV_STAMMSEKTION_ROLES +
    SacCas::NEUANMELDUNG_NV_ZUSATZSEKTION_ROLES

  private

  def perform_internal
    stale_roles.in_batches(of: 25) do |roles|
      Role.transaction do
        terminate_roles_and_cancel_invoices(roles)
      end
    end
  end

  def terminate_roles_and_cancel_invoices(roles)
    cancellable_invoices_for(roles).each do |invoice|
      invoice.update!(state: :cancelled)
      Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    end
    roles.update_all(end_on: Time.zone.yesterday, terminated: true)
  end

  def cancellable_invoices_for(roles)
    roles.flat_map do |role|
      ExternalInvoice::SacMembership
        .where(person_id: role.person_id)
        .where(link: role.layer_group)
        .select(&:cancellable?)
    end
  end

  def stale_roles
    @stale_roles ||= Role.where(
      terminated: false,
      type: ROLE_TYPES.map(&:sti_name),
      start_on: ..4.months.ago
    )
  end

  def next_run
    interval.from_now.midnight + 5.minutes
  end
end
