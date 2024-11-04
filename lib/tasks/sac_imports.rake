# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :sac_imports do
  def skip_existing? = ["1", "true"].exclude?(ENV["REIMPORT_ALL"].to_s.downcase)

  task setup: [:environment] do
    Person.skip_callback(:commit, :after, :transmit_data_to_abacus)
    Group::SektionsMitglieder::Mitglied.skip_callback(:commit, :after, :transmit_data_to_abacus)

    Person.skip_callback(:save, :after, :check_data_quality)
    Group::SektionsMitglieder::Mitglied.skip_callback(:create, :after, :check_data_quality)
    Group::SektionsMitglieder::Mitglied.skip_callback(:destroy, :after, :check_data_quality)
    Group::SektionsMitglieder::MitgliedZusatzsektion.skip_callback(:create, :after, :check_data_quality)
    Group::SektionsMitglieder::MitgliedZusatzsektion.skip_callback(:destroy, :after, :check_data_quality)
    PhoneNumber.skip_callback(:create, :after, :check_data_quality)
    PhoneNumber.skip_callback(:destroy, :after, :check_data_quality)
  end

  desc "Imports SAC Sections"
  task "nav6-1_sac_sections": :setup do
    SacImports::SacSectionsImporter.new.create
  end

  desc "Imports people and companies from Navision"
  task "nav1-1_people": :setup do
    SacImports::PeopleImporter.new.create(start_at_navision_id: ENV["START_AT_NAVISION_ID"])
  end

  desc "Import people from WSO2"
  task "wso21-1_people": :setup do
    SacImports::Wso2PeopleImporter.new.create
  end

  desc "Imports membership roles"
  task "nav2-1-membership_roles": :setup do
    SacImports::Nav21RolesMembershipImporter.new.create
  end

  desc "Imports missing groups"
  task "nav2-21-create_missing_groups": [:environment] do
    SacImports::Nav221CreateMissingGroups.new.create
  end

  desc "Imports non-membership roles"
  task "nav2-22-non_membership_roles": :setup do
    SacImports::Nav222RolesNonMembershipImporter.new.create
  end

  desc "Imports families"
  task "nav1-2_sac_families": [:environment] do
    SacImports::FamilyImporter.new.create
  end

  desc "Analyzes imported and calculated membership years and creates report"
  task "nav1-2_membership_years_report": [:environment] do
    SacImports::MembershipYearsReport.new.create
  end

  desc "Imports qualifications"
  task "nav3-1_qualifications": [:environment] do
    SacImports::QualificationsImporter.new.create
  end

  desc "Imports huts"
  task "nav5-1_huts": [:environment] do
    SacImports::HutsImporter.new.import!
  end

  desc "Imports Austrittsgründe"
  task "nav8-1_austrittsgruende": [:environment] do
    raise "Not implemented"
  end
end
