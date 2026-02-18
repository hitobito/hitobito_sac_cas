# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::EventsController
  extend ActiveSupport::Concern

  prepended do
    self.permitted_attrs += [
      :fitness_requirement_id,
      discipline_ids: [],
      target_group_ids: [],
      technical_requirement_ids: [],
      trait_ids: []
    ]

    before_render_form :preload_translated_associations
    before_render_form :preload_tour_essentials

    after_update :display_warning_for_date_changes, if: :tour?

    helper_method :course?, :tour?
  end

  private

  def display_warning_for_date_changes
    if entry.dates_changed? && !entry.weak_validation_state?
      flash[:warning] = I18n.t("events.flash.dates_changed", event_name: entry.name)
      flash[:notice] = nil
    end
  end

  def preload_translated_associations
    return unless course?

    @cost_centers = CostCenter.assignable(entry.cost_center_id).list
    @cost_units = CostUnit.assignable(entry.cost_unit_id).list
  end

  def preload_tour_essentials # rubocop:disable Metrics/AbcSize
    return unless tour?

    @disciplines = Event::Discipline.assignable(entry.discipline_ids).list
    @target_groups = Event::TargetGroup.assignable(entry.target_group_ids).list
    @technical_requirements =
      Event::TechnicalRequirement.assignable(entry.technical_requirement_ids).list
    @fitness_requirements = Event::FitnessRequirement.assignable(entry.fitness_requirement_id).list
    @traits = Event::Trait.assignable(entry.trait_ids).list
  end

  def course? = entry.is_a?(Event::Course)

  def tour? = entry.is_a?(Event::Tour)
end
