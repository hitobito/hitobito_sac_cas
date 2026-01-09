# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::DisciplinesController < SimpleCrudController
  self.permitted_attrs = [:label, :short_description, :description, :order, :parent_id]

  self.sort_mappings = {
    label: "event_discipline_translations.label"
  }

  before_render_form :load_parents

  def show
    redirect_to edit_event_discipline_path(entry)
  end

  def self.model_class
    Event::Discipline
  end

  private

  def list_entries
    model_scope.main.list
  end

  def load_parents
    @parents = model_class.main.list.without_deleted
  end

  # overwrite to avoid clash with @parents list for form
  def parents
    @nestable_parents ||= load_fixed_parents + load_optional_parents
  end

  def assign_attributes
    super
    entry.deleted_at = nil # restore on edit
  end
end
