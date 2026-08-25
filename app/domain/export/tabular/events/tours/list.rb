# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Export::Tabular::Events::Tours
  class List < Export::Tabular::Events::List
    self.row_class = Export::Tabular::Events::Tours::Row

    private

    def build_attribute_labels
      {}.tap do |labels|
        labels[:id] = human_attribute(:id)
        add_main_labels(labels)
        add_date_labels(labels)
        add_tour_essential_labels(labels)
        add_contact_labels(labels)
        add_additional_labels(labels)
        add_tour_price_labels(labels)
        add_count_labels(labels)
        add_tour_association_labels(labels)
      end
    end

    def add_tour_essential_labels(labels)
      labels[:season] = human_attribute(:season)
      labels[:summit] = human_attribute(:summit)
      labels[:elevation] = I18n.t("global.elevation_label")
      labels[:duration_in_hours] = human_attribute(:duration_in_hours)
      labels[:tourenportal_link] = human_attribute(:tourenportal_link)
      labels[:maps] = human_attribute(:maps)
      labels[:alternative_route] = human_attribute(:alternative_route)
      labels[:additional_info] = human_attribute(:additional_info)
    end

    def add_additional_labels(labels)
      labels[:leaders] = translate(:leaders)
      add_used_attribute_label(labels, :minimum_participants)

      super
    end

    def add_tour_price_labels(labels)
      labels[:prices] = I18n.t("events.form_tabs.prices")
      labels[:price_special] = human_attribute(:price_special)
      labels[:price_member] = human_attribute(:price_member)
      labels[:price_regular] = human_attribute(:price_regular)
      labels[:price_description] = translate(:price_description)
    end

    def add_tour_association_labels(labels)
      labels[:activities] = human_attribute(:activities)
      labels[:target_groups] = human_attribute(:target_groups)
      labels[:fitness_requirement] = human_attribute(:fitness_requirement_id)
      labels[:technical_requirements] = human_attribute(:technical_requirements)
      labels[:traits] = human_attribute(:traits)
    end

    def model_class
      @model_class ||= list.first ? list.first.class : ::Event::Tour
    end
  end
end
