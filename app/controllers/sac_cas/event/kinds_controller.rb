# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Event::KindsController
  extend ActiveSupport::Concern

  prepended do
    self.permitted_attrs += [
      :level_id,
      :cost_center_id,
      :cost_unit_id,
      :maximum_participants,
      :minimum_participants,
      :maximum_age,
      :ideal_class_size,
      :maximum_class_size,
      :training_days,
      :season,
      :reserve_accommodation,
      :accommodation,
      course_compensation_category_ids: []
    ]
  end

  def push_down
    authorize!(:update, entry)
    entry.push_down_inherited_attributes!
    redirect_to edit_event_kind_path(entry), flash: {notice: t(".success")}
  end

  private

  def load_assocations
    super
    @cost_centers = CostCenter.list
    @cost_units = CostUnit.list
    @kind_categories = Event::KindCategory.list
    @course_compensation_categories = CourseCompensationCategory.where(kind: [:day, :flat])
  end
end
