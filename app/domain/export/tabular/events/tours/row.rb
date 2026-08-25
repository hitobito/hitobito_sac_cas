# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Export::Tabular::Events::Tours
  class Row < Export::Tabular::Events::Row
    def season
      entry.season_label
    end

    def elevation
      [ascent_text, descent_text].compact.join(" / ")
    end

    # All leaders and assistant leaders, formatted as "Vorname Nachname (Rolle)".
    def leaders
      leader_types = entry.role_types.select(&:leader?)
      entry.participations_for(*leader_types).flat_map do |participation|
        participation.roles.select { |role| role.class.leader? }.map do |role|
          "#{participation.person} (#{role.class.label})"
        end
      end.join(", ")
    end

    def prices
      Event::Tour::PRICE_ATTRIBUTES.filter_map do |attr|
        value = entry.send(attr)
        next if value.blank?

        "#{entry.class.human_attribute_name(attr)}: #{format_price(value)}"
      end.join(", ")
    end

    def price_special = format_price(entry.price_special)

    def price_member = format_price(entry.price_member)

    def price_regular = format_price(entry.price_regular)

    def activities
      essential_children(entry.activities)
    end

    def target_groups
      essentials_label_list(entry.target_groups)
    end

    def technical_requirements
      essential_children(entry.technical_requirements)
    end

    def traits
      essential_children(entry.traits)
    end

    private

    def ascent_text
      "#{entry.ascent} ↗" if entry.ascent.present?
    end

    def descent_text
      "#{entry.descent} ↘" if entry.descent.present?
    end

    def format_price(value)
      value&.to_s("F")
    end

    def essential_children(essentials)
      essentials_label_list(essentials.reject(&:main?))
    end

    def essentials_label_list(essentials)
      essentials.map(&:label).sort.join(", ")
    end
  end
end
