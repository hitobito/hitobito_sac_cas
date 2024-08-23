# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
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
    membership_manager.update_membership_status if person && group
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
end
