# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventsController
  extend ActiveSupport::Concern

  prepended do
    before_render_form :preload_translated_associations
  end

  private

  def preload_translated_associations
    return unless  entry.type == 'Event::Course'

    @cost_centers = CostCenter.includes(:translations).list
    @cost_units = CostUnit.includes(:translations).list
  end
end
