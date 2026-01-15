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
      technical_requirement_ids: []
    ]

    before_render_form :preload_translated_associations
    before_render_form :preload_disciplines
    before_render_form :preload_target_groups
    before_render_form :preload_technical_requirements
    before_render_form :preload_fitness_requirements
  end

  private

  def preload_translated_associations
    return unless entry.type == "Event::Course"

    @cost_centers = CostCenter.includes(:translations).list
    @cost_units = CostUnit.includes(:translations).list
  end

  def preload_disciplines
    return unless entry.respond_to?(:disciplines)

    @main_disciplines = Event::Discipline.main.list.includes(:translations, children: :translations)
  end

  def preload_target_groups
    return unless entry.respond_to?(:target_groups)

    @main_target_groups =
      Event::TargetGroup.main.list.includes(:translations, children: :translations)
  end

  def preload_technical_requirements
    return unless entry.respond_to?(:technical_requirements)

    @main_technical_requirements =
      Event::TechnicalRequirement.main.list.includes(:translations, children: :translations)
  end

  def preload_fitness_requirements
    return unless entry.respond_to?(:fitness_requirement)

    @fitness_requirements = Event::FitnessRequirement.list.includes(:translations)
  end
end
