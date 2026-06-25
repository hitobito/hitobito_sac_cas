# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::Event
  class SacCourseFinances < Export::Tabular::Base
    self.model_class = ::Event::Course
    self.row_class = Row

    class_attribute :attributes
    self.attributes = [
      :event_kind_category_order,
      :event_kind_category_label,
      :event_kind_short_name,
      :event_kind_label,

      :season,
      :name,
      :start_on,
      :finish_on,
      :state,
      :language,
      :closed_month,

      :total_revenue,
      :leader_count,
      :leader_compensations,
      :minimum_participants,
      :maximum_participants,
      :attended_count,
      :absent_count,

      *Event::Participation.price_categories.keys.flat_map do |category|
        [category.to_sym, :"#{category}_count"]
      end,

      *ParticipantCountByAge::AGE_GROUPS.values.map do |key|
        :"#{key}_count"
      end,

      :sac_member_count,
      :non_sac_member_count
    ]

    attr_reader :year

    def initialize(year)
      @year = year
      super(event_scope.to_a)
    end

    def event_scope
      Event::Course
        .with_group_id(Group.root_id)
        .in_year(@year)
        .where(state: :closed)
        .list
        .includes(:translations, kind: [:translations, kind_category: :translations])
    end

    def course_ids
      @course_ids ||= list.map(&:id)
    end

    def row_for(entry, format = nil)
      row_class.new(entry, format, course_data(entry.id))
    end

    def course_data(id)
      {
        total_revenue: total_revenues.fetch(id, 0),
        leader_compensations: leader_compensations.fetch(id, 0),
        participant_counts_by_state: participant_counts_by_state.fetch(id, {}),
        participant_counts_by_price: participant_counts_by_price.fetch(id, {}),
        participant_counts_by_age: participant_counts_by_age.fetch(id, {}),
        participant_counts_by_membership: participant_counts_by_membership.fetch(id, {})
      }
    end

    def total_revenues
      @total_revenues ||= TotalRevenue.new.fetch(course_ids)
    end

    def leader_compensations
      @leader_compensations ||= LeaderCompensations.new.fetch(course_ids)
    end

    def participant_counts_by_state
      @participant_counts_by_state ||= ParticipantCountByState.new.fetch(course_ids)
    end

    def participant_counts_by_price
      @participant_counts_by_price ||= ParticipantCountByPrice.new.fetch(course_ids)
    end

    def participant_counts_by_age
      @participant_counts_by_age ||= ParticipantCountByAge.new.fetch(course_ids)
    end

    def participant_counts_by_membership
      @participant_counts_by_membership ||= ParticipantCountByMembership.new.fetch(course_ids)
    end

    def attribute_label(attr)
      I18n.t("export/tabular/event/sac_course_finances.attributes.#{attr}")
    end
  end
end
