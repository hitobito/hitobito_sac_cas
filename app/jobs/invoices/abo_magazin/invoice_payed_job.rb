# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Invoices::AboMagazin::InvoicePayedJob < BaseJob
  self.parameters = [:person_id, :group_id]

  def initialize(person_id, group_id)
    super()
    @person_id = person_id
    @group_id = group_id
  end

  def perform
    abonnent_manager.update_abonnent_status if person && group
  end

  private

  def abonnent_manager
    Invoices::AboMagazin::AbonnentManager.new(person, group)
  end

  def person
    @person ||= Person.find(@person_id)
  end

  def group
    @group ||= Group.find(@group_id)
  end
end
