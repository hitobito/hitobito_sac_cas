# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Xlsx::MitgliederStatistics
  class SectionEintritte < Section
    self.groupings = [:gender, :language, :age, :beitragskategorie, :self_registration_reason]

    private

    def scope
      Role
        .unscoped
        .joins(:person)
        .where(group_id: group.id, type: SacCas::MITGLIED_ROLES.map(&:sti_name))
        .where(start_on: range) # FIXME
    end

    def count_by_self_registration_reason
      counts = scope.group(:self_registration_reason_id).count
      self_registration_reasons.each_with_object({}) do |(id, text), hash|
        hash[text] = counts[id] || 0
      end
    end

    def self_registration_reasons
      # Hash with id => text
      {nil => nil}.merge(
        SelfRegistrationReason
          .all
          .sort_by(&:text)
          .index_by(&:id)
          .transform_values(&:text)
      )
    end
  end
end
