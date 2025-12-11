# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class AustritteRow < MitgliedschaftRow
    attr_reader :group

    def initialize(entry, group, range, format = nil)
      @range = range
      super(entry, group, format)
    end

    def sac_is_terminated
      membership_role.end_on == roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES).last.end_on
    end

    def sac_is_section_change
      !roles(*SacCas::MITGLIED_STAMMSEKTION_ROLES)
        .select { |r| r.end_on > @range.first }
        .last(2).map(&:group_id).uniq.one?
    end

    def end_on
      membership_role.end_on
    end

    def termination_reason
      membership_role.termination_reason_text.presence ||
        I18n.t("export/tabular/people/mitgliedschaft.attributes.no_termination_reason")
    end

    def data_retention_consent
      roles(Group::AboBasicLogin::BasicLogin).any?
    end

    private

    def membership_role
      @membership_role ||= descending_membership_roles.find do |r|
        @range.cover?(r.end_on)
      end
    end

    def descending_membership_roles
      @descending_membership_roles ||= group_membership_roles.reverse
    end
  end
end
