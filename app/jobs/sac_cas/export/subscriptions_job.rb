# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Export::SubscriptionsJob
  private

  def data
    return recipients_data if @options[:recipients]
    return recipient_households_data if @options[:recipient_households]
    return recipient_table_display_without_membership_years if @options[:selection]

    super
  end

  def entries
    super.select("household_key")
  end

  # As adding .with_membership_years entries does not work we ignore membership_years column
  def recipient_table_display_without_membership_years
    table_display = TableDisplay.for(@user_id, Person)
    table_display.selected -= %w[membership_years]
    Export::Tabular::People::TableDisplays.export(@format, entries, table_display)
  end

  def recipients_data
    Export::Tabular::People::SacRecipients.export(@format, entries, mailing_list.group)
  end

  def recipient_households_data
    Export::Tabular::People::SacRecipientHouseholds.export(@format, entries, mailing_list.group)
  end
end
