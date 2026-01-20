# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::NestableTourEssentialsController < SimpleCrudController
  self.permitted_attrs = [:label, :short_description, :description, :order, :parent_id]

  before_render_form :load_parents

  private

  def list_entries
    super.main.list.tap do |list|
      ActiveRecord::Associations::Preloader.new(
        records: list,
        associations: [:children],
        scope: model_class.list
      ).call
    end
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
