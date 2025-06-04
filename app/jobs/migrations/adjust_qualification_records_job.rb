# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  # A one-off job to adjust qualifications records to the requirements
  # of hitobito. Specifically, create a record for the last qualification
  # during the kind's validity period if the imported qualification
  # has a longer validity.
  # Implements https://saccas.atlassian.net/browse/HIT-1176
  class AdjustQualificationRecordsJob < BaseJob
    def perform
      init_stats
      PaperTrail.request(enabled: false) do
        people_with_active_qualifications.find_each(batch_size: 50) do |person|
          create_last_qualifications(person)
        end
      end
      @stats
    end

    def people_with_active_qualifications
      Person.joins(qualifications: :qualification_kind)
        .where(qualifications: {finish_at: Date.new(2025, 1, 1)..})
        .where.not(qualification_kinds: {validity: nil})
        .includes(qualifications: :qualification_kind)
        .distinct
    end

    private

    def create_last_qualifications(person)
      person.qualifications.group_by(&:qualification_kind).each do |quali_kind, qualifications|
        next unless quali_kind.validity

        last_qualification = qualifications.max_by { |q| [q.finish_at, q.start_at] }
        finish_at = last_qualification.finish_at
        if finish_at.year >= 2025 && finish_at.year - last_qualification.start_at.year > quali_kind.validity
          create_qualification(last_qualification)
          @stats[quali_kind.label] << person.id
        end
      end
    end

    def create_qualification(qualification)
      start_year = qualification.finish_at.year - qualification.qualification_kind.validity
      Qualification.create!(
        person: qualification.person,
        qualification_kind: qualification.qualification_kind,
        start_at: Date.new(start_year, 12, 31)
      )
    end

    def init_stats
      @stats = Hash.new { |h, k| h[k] = [] }
    end
  end
end
