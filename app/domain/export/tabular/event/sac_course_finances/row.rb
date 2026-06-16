#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::Event::SacCourseFinances
  class Row < Export::Tabular::Row
    attr_reader :data

    def initialize(entry, format = nil, data = {})
      super(entry, format)
      @data = data
    end

    def event_kind_category_order
      entry.kind.kind_category.order
    end

    def event_kind_category_label
      entry.kind.kind_category.label
    end

    def event_kind_short_name
      entry.kind.short_name
    end

    def event_kind_label
      entry.kind.label
    end

    def season
      entry.season_label
    end

    def start_on
      entry.start_at.to_date
    end

    def finish_on
      entry.finish_at.to_date
    end

    def state
      I18n.t("activerecord.attributes.#{entry.class.name.underscore}.states.#{entry.state}")
    end

    def closed_month
      entry.closed_at&.strftime("%Y-%m")
    end

    def total_revenue
      data[:total_revenue]
    end

    def leader_count
      entry.teamer_count
    end

    def leader_compensations
      data[:leader_compensations]
    end

    def attended_count
      data[:participant_counts_by_state].fetch(:attended, 0)
    end

    def absent_count
      data[:participant_counts_by_state].fetch(:absent, 0)
    end

    Event::Participation.price_categories.keys.each do |category|
      define_method :"#{category}_count" do
        data[:participant_counts_by_price].fetch(category.to_sym, 0)
      end
    end

    ParticipantCountByAge::AGE_GROUPS.values.each do |key|
      define_method :"#{key}_count" do
        data[:participant_counts_by_age].fetch(key, 0)
      end
    end

    def sac_member_count
      data[:participant_counts_by_membership].fetch(true, 0)
    end

    def non_sac_member_count
      data[:participant_counts_by_membership].fetch(false, 0)
    end
  end
end
