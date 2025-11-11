# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class CorrectCorrespondenceRelatedPeopleFields < ActiveRecord::Migration[8.0]
  def up
    set_confirmed_at_to_migration_ts_for_members_with_email_and_legacy_pw
    set_confirmed_at_null_for_members_without_email
    set_correspondence_print_for_unconfirmed_members_with_email
  end

  private

  def set_confirmed_at_to_migration_ts_for_members_with_email_and_legacy_pw
    say_with_time("setting confirmed_at to migration timestamp") do
      members
        .where.not(email: nil).where.not(wso2_legacy_password_hash: nil)
        .where(correspondence: :digital, confirmed_at: Time.at(0))
        .update_all(confirmed_at: Time.zone.local(2024, 12, 21, 21))
    end
  end

  def set_confirmed_at_null_for_members_without_email
    say_with_time("resetting confirmed_at for empty emails") do
      members
        .where(email: nil, correspondence: :print)
        .where.not(confirmed_at: nil)
        .update_all(confirmed_at: nil)
    end
  end

  def set_correspondence_print_for_unconfirmed_members_with_email
    say_with_time "set correspondence print" do
      members
        .where.not(email: nil)
        .where(correspondence: :digital, wso2_legacy_password_hash: nil)
        .where(confirmed_at: [nil, Time.at(0)])
        .update_all(correspondence: :print)
    end
  end

  def members
    Person.joins(:roles).where(roles: {type: SacCas::MITGLIED_ROLES.map(&:sti_name)}).distinct
  end
end
