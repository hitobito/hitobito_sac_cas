# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Person::ExternalInvoicesController < ListController
  private

  def list_entries
    scope = ExternalInvoice
      .where(search_conditions)
      .where(person: person).list

    scope.page(params[:page]).per(50)
  end

  def person
    @person ||= fetch_person
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def authorize_class
    authorize!(:index_external_invoices, person)
  end
end
