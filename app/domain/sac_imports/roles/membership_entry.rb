# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::Roles
  class MembershipEntry
    include EntryHelper

    def initialize(row)
      @row = row
      @skipped = false
    end

    def errors
      build_error_messages
    end

    def warnings
      build_warning_messages
    end

    def valid?
      errors.empty?
    end

    def skipped?
      errors.present? && @skipped
    end

    def import!
      return if skipped?
      "Importing..."
    end

    private

    def person
      @person ||= ::Person.find_by(id: navision_id)
    end

    def todo?
      @row.values.any? { |value| value.is_a?(String) && value.include?("TODO") }
    end

    def navision_id
      @navision_id ||= Integer(@row[:navision_id].to_s.sub(/^0*/, ""))
    end

    def build_error_messages
      errors ||= []

      errors << skip("Person not found") if person.nil?
      errors << skip("Row contains TODO") if todo?
      errors << [person.errors.full_messages, person.roles.first.errors.full_messages].flatten.compact if person.present?

      errors.join(", ")
    end

    def build_warning_messages
      warnings ||= []

      warnings.join(", ")
    end
  end
end
