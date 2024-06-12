# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Invoice
  extend ActiveSupport::Concern

  INVOICE_KINDS = %w(membership course).freeze

  prepended do
    i18n_enum :invoice_kind, INVOICE_KINDS
  end

  def recalculate
    super if invoice_items.present?
  end
end
