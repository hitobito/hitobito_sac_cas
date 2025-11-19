# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class SectionAustritte < Section
    self.groupings = [:gender, :language, :age, :beitragskategorie, :termination_reason]

    private

    def scope
      roles = Export::Tabular::People::AustritteScope.new(@group, @range).roles
      rownum = "ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY end_on DESC) AS rownum"
      ranked = Role.unscoped.from(roles.select(:id, rownum)).where("rownum = 1")

      Role.unscoped.where("roles.id IN (?)", ranked.select(:id)).joins(:person) # rubocop:disable Rails/WhereEquals
    end

    def count_by_termination_reason
      counts = scope.group(:termination_reason_id).count
      termination_reasons.each_with_object({}) do |(id, text), hash|
        hash[text] = counts[id] || 0
      end
    end

    def termination_reasons
      # Hash with id => text
      {nil => nil}.merge(
        TerminationReason
          .all
          .sort_by(&:text)
          .index_by(&:id)
          .transform_values(&:text)
      )
    end
  end
end
