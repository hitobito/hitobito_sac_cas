# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipEntry
    attr_reader :row

    def initialize(row)
      @row = row
    end

    def valid?
      person.present? && person.valid?
    end

    def errors
      @errors ||= build_error_messages
    end

    def import!
      person.save!
    end

    private

    def person
      @person ||= ::Person.find_by(id: navision_id)
    end

    def todo?
      row.values.any? { |value| value.is_a?(String) && value.include?("TODO") }
    end

    def navision_id
      @navision_id ||= Integer(row[:navision_id].to_s.sub(/^0*/, ""))
    end

    def build_error_messages
      errors = []

      errors << "Person not found" if person.nil?
      errors << "Skipping because row contains TODO" if todo?
      errors << [person.errors.full_messages, person.roles.first.errors.full_messages].flatten.compact if person.present?

      errors.join(", ")
    end
  end
end
