# frozen_string_literal: true

# Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito_sac_cas.

class Event::FitnessRequirementResource < ApplicationResource
  primary_endpoint "event_fitness_requirements", %i[index show]

  self.type = "event_fitness_requirements"

  with_options writable: false do
    attribute :label, :string
    attribute :short_label, :string
    attribute :short_description, :string
    attribute :description, :string
    attribute :order, :integer
  end

  def base_scope
    Event::FitnessRequirement.without_deleted
  end
end
