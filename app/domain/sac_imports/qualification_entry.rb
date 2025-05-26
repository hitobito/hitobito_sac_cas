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
    validate :nav3_active_matches_qualification_active

    def nav3_active_matches_qualification_active
      if qualification && row.active == "1" && !qualification.active?
        @warning = "Active in NAV3 but would be inactive by hitobito"
      end
      if qualification && row.active != "1" && qualification.active?
        @warning = "Inactive in NAV3 but would be active by hitobio"
      end
    end

    attr_reader :row
    attr_reader :warning

    def initialize(row)
      @row = row
      @warning = nil
    end

    def valid?
      self_valid = super
      qualification_valid = qualification&.valid?
      errors.merge!(qualification.errors) if !qualification.nil?
      self_valid && qualification_valid
    end

    def import!
      qualification.save!
    end

    def error_messages
      errors.full_messages.join(", ")
    end

    def qualification
      @qualification ||= person&.qualifications&.find_or_initialize_by(
        qualification_kind_id: qualification_kind_id, start_at: row.start_at, finish_at: row.finish_at)
    end

    def qualification_kind_id
      @qualification_kind_id ||= QualificationKind.find_by(label: row.qualification_kind)&.id
    end

    def person
      @person ||= Person.find_by_id(row.navision_id)
    end
  end
end
