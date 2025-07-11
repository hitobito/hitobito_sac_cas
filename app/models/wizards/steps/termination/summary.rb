#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    module Termination
      class Summary < Step
        attribute :termination_reason_id, :integer
        attribute :entry_fee_consent, :boolean
        attribute :data_retention_consent, :boolean
        attribute :subscribe_newsletter, :boolean
        attribute :subscribe_fundraising_list, :boolean
        attribute :inform_via_email, :boolean, default: true

        validates :termination_reason_id, presence: true
        validates :entry_fee_consent, acceptance: true

        def family_member_names
          wizard.person.household.members.map { |m| m.person.full_name }.to_sentence
        end

        def termination_reason_options
          TerminationReason.includes(:translations).all.map { |r| [r.text, r.id] }
        end

        def family_membership?
          wizard.family_membership?
        end

        def mitglied_termination_by_section_only?
          wizard.mitglied_termination_by_section_only?
        end
      end
    end
  end
end
