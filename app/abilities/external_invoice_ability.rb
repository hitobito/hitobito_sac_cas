# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalInvoiceAbility < AbilityDsl::Base
  include AbilityDsl::Constraints::Person

  on(ExternalInvoice) do
    # index on a specific person is allowed via Person :index_external_invoices
    class_side(:index).if_backoffice

    # not possible to use :manage here because that would open up the :index
    # action to all :layer_and_below_full roles on all layers
    permission(:layer_and_below_full)
      .may(:show, :create, :update, :destroy, :cancel, :record_payment)
      .if_backoffice
  end

  def person
    subject.person
  end

  def if_backoffice
    role_type?(*SacCas::SAC_BACKOFFICE_ROLES) ||
      (user.service_token&.layer&.root? &&
       user.service_token&.permission == "layer_and_below_full")
  end
end
