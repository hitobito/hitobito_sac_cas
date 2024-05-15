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

    send_data csv, type: 'text/plain; charset=utf-8', disposition: 'inline'
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

  def positions # rubocop:disable Metrics/CyclomaticComplexity
    @positions ||=
      if entry.new_entry_membership_role
        generator.new_entry_positions.map(&:to_h)
      elsif entry.new_additional_section_membership_roles.present?
        section = entry.new_additional_section_membership_roles.first.layer_group
        generator.new_additional_section_positions(section).map(&:to_h)
      else
        generator.membership_positions.map(&:to_h)
      end
  end

  def generator
    Invoices::SacMemberships::PositionGenerator.new(entry)
  end

  def entry
    @entry ||= Invoices::SacMemberships::Person.new(person, context)
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def person
    Person.with_membership_years('people.*', date).find(params[:id])
  end

  def date
    @date ||= params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  end

end
