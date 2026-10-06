# frozen_string_literal: true

#  Copyright (c) 2024-2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::SacMemberships::InvoicePayedJob < BaseJob
  self.parameters = [:person_id, :group_id, :year]

  def initialize(person_id, group_id, year)
    super()
    @person_id = person_id
    @group_id = group_id
    @year = year
  end

  def perform
    if person && group
      membership_manager.update_membership_status
    else
      create_log_entry(:error, t(:record_not_found, person_id: @person_id, group_id: @group_id))
    end
  end

  def error(_job, exception, payload = parameters)
    create_log_entry(:error, t(:failed, section: group&.layer_group), exception)
    super
  end

  private

  attr_reader :year

  def membership_manager
    Invoices::SacMemberships::MembershipManager.new(person, group, year)
  end

  def person
    @person ||= Person.find_by(id: @person_id)
  end

  def group
    @group ||= Group.find_by(id: @group_id)
  end

  def t(key, **)
    I18n.t("invoices.sac_memberships.invoice_payed_job.#{key}", year:, **)
  end

  def create_log_entry(level, message, exception = nil)
    HitobitoLogEntry.create!(
      category: "rechnungen",
      level:,
      subject: person,
      message:,
      payload: exception && "#{exception.class}: #{exception.message}"
    )
  end
end
