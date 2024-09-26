# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class QualificationEntry
    include ActiveModel::Validations

    validates :person, presence: {message: "couldn't be found"}
    validates :qualification_kind_id, presence: {message: "couldn't be found"}

    attr_reader :row

    def initialize(row)
      @row = row
    end

    def import!
      qualification.save!
    end

    def error_messages
      errors.full_messages.join(", ")
    end

    def qualification
      @qualification ||= person.qualifications.find_or_initialize_by(qualification_kind_id: qualification_kind_id) do |qualification|
        qualification.start_at = row[:start_at]
        qualification.finish_at = row[:finish_at]
      end
    end

    def qualification_kind_id
      @qualification_kind_id ||= QualificationKind.find_by(label: row[:qualification_kind])&.id
    end

    def person
      @person ||= Person.find_by_id(row[:navision_id])
    end
  end
end
