# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::KindCategoriesController
  extend ActiveSupport::Concern

  prepended do
    self.permitted_attrs += [:cost_center_id, :cost_unit_id]
  end

  def push_down
    authorize!(:update, entry)
    entry.push_down_inherited_attributes!
    message = t(".success", cost_center: entry.cost_center, cost_unit: entry.cost_unit)
    redirect_to edit_event_kind_category_path(entry), flash: {notice: message}
  end

  private

  def load_assocations
    super
    @cost_centers = CostCenter.includes(:translations).list
    @cost_units = CostUnit.includes(:translations).list
  end

  def list_entries
    super.includes(:translations,
      cost_center: :translations,
      cost_unit: :translations,
      kinds: :translations)
  end
end
