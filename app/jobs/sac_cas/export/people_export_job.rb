# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Export::PeopleExportJob
  def entries
    super.with_membership_years
  end

  private

  def data
    return recipients_data if @options[:recipients]
    return recipient_households_data if @options[:recipient_households]

    super
  end

  def recipients_data
    Export::Tabular::People::SacRecipients.export(@format, entries, group)
  end

  def recipient_households_data
    Export::Tabular::People::SacRecipientHouseholds.export(@format, entries, group)
  end
end
