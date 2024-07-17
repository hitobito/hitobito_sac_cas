# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::EventKindsHelper
  def labeled_compensation_categories_field(form, collection, title)
    selected = entry.course_compensation_categories

    # Unify collection with selected, to include them even if they are marked as deleted.
    options = collection | selected

    form.labeled(title) do
      content_tag(:div, class: "col-6") do
        "gugus"
        # select_tag("event_kind[course_compensation_categories][qualification_kind_ids]",
        #  options_from_collection_for_select(options, :id, :to_s, selected.collect(&:id)),
        #  multiple: true,
        #  class: "form-select form-select-sm tom-select")
      end
    end
  end
end
