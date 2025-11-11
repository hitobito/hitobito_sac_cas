# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Memberships::TerminateSacMembershipForm < Memberships::TerminationForm
  attribute :subscribe_newsletter, :boolean, default: false
  attribute :subscribe_fundraising_list, :boolean, default: false
  attribute :data_retention_consent, :boolean, default: false
  attribute :entry_fee_consent, :boolean

  validates :entry_fee_consent, acceptance: true

  def attributes_for_operation
    super.except(:entry_fee_consent)
  end
end
