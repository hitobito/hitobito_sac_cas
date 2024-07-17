# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# This controller only exists for testing purposes until membership invoices
# are sent to abacus. It may be removed then.
class People::MembershipInvoicePositionsController < ApplicationController
  def show
    authorize!(:update, person)

    render plain: csv, type: "text/plain; charset=utf-8"
  end

  private

  def csv
    CSV.generate do |csv|
      csv << positions.first.keys if positions.present?
      positions.each do |hash|
        csv << hash.values
      end
    end
  end

  def positions
    @positions ||=
      Invoices::SacMemberships::PositionGenerator
        .new(member)
        .generate(current_memberships, new_entry: @new_entry)
        .map(&:to_h)
  end

  def current_memberships
    if member.new_entry_role
      @new_entry = true
      [member.membership_from_role(member.new_entry_role, main: true)]
    elsif member.new_additional_section_membership_roles.present?
      [member.membership_from_role(member.new_additional_section_membership_roles.first)]
    else
      member.active_memberships
    end
  end

  def member
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def person
    Person.with_membership_years("people.*", date).find(params[:id])
  end

  def date
    @date ||= params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  end
end
