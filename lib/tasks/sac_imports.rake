# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :sac_imports do
  def skip_existing? = ["1", "true"].exclude?(ENV["REIMPORT_ALL"].to_s.downcase)

  task setup: [:environment] do
    ENV["NO_ENV"] = "true" # makes sure we don't seed dev seeds

    Rails.logger = Logger.new(nil)
    ActiveRecord::Base.logger = Logger.new(nil)

    Truemail.configuration.default_validation_type = :regex

    PaperTrail.enabled = false # disable versioning for imports

    Person.skip_callback(:update, :after, :schedule_duplicate_locator)
    Person.skip_callback(:commit, :after, :transmit_data_to_abacus)
    Group::SektionsMitglieder::Mitglied.skip_callback(:commit, :after, :transmit_data_to_abacus)
    Group::AboMagazin::Abonnent.skip_callback(:commit, :after, :transmit_data_to_abacus)

    Person.skip_callback(:save, :after, :check_data_quality)
    Group::SektionsMitglieder::Mitglied.skip_callback(:create, :after, :check_data_quality)
    Group::SektionsMitglieder::Mitglied.skip_callback(:destroy, :after, :check_data_quality)
    Group::SektionsMitglieder::MitgliedZusatzsektion.skip_callback(:create, :after, :check_data_quality)
    Group::SektionsMitglieder::MitgliedZusatzsektion.skip_callback(:destroy, :after, :check_data_quality)
    PhoneNumber.skip_callback(:create, :after, :check_data_quality)
    PhoneNumber.skip_callback(:destroy, :after, :check_data_quality)
    PeopleManager.skip_callback(:create, :after, :create_paper_trail_versions_for_create_event)
    PeopleManager.skip_callback(:destroy, :after, :create_paper_trail_versions_for_destroy_event)
  end

  desc "Enable debug logging"
  task debug: :setup do
    Rails.logger = Logger.new(SacImports::CsvReport::LOG_DIR.join("rails.log"))
    ActiveRecord::Base.logger = Logger.new(SacImports::CsvReport::LOG_DIR.join("activerecord.log"))
  end

  task prepare_database: [
    "sac_imports:setup",
    "db:drop",
    "db:create",
    "db:migrate",
    "wagon:migrate",
    "sac_imports:seed"
  ]

  task :seed do
    # seeds can't be run in the same process as migrations, so we do it in a subprocess
    system("NO_ENV=true bundle exec rails db:seed wagon:seed")
  end

  task all: [
    :setup,
    :"nav6-1_sac_section",
    "nav5-1_huts",
    "nav2b-1_missing_groups",
    "nav1-1_people",
    "nav3-1_qualifications",
    "nav2a-1_membership_roles",
    "nav1-2_membership_years_report",
    "nav2a-2_set_family_main_person",
    "nav2a-3_families",
    "wso21-1_people",
    "nav2b-2_non_membership_roles",
    "nav1-3_subscriptions",
    "chimp-subscriptions",
    :update_sac_family_address,
    "nav17-1_event_kinds",
    "nav18-1_events",
    "nav21-1_event-participations",
    :cleanup,
    :check_data_quality
  ] do
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "final_dump")
    puts "\e[42;31;1m 😃 All imports done and final DB dump completed 😃 \e[0m"
  end

  desc "Imports SAC Sections"
  task "nav6-1_sac_section": :setup do
    SacImports::Nav6SectionsImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav6-sections")
  end

  desc "NAV1 Imports people and companies from Navision"
  task "nav1-1_people": :setup do
    SacImports::Nav1PeopleImporter.new.create(start_at_navision_id: ENV["START_AT_NAVISION_ID"])
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav1-1_people")
  end

  desc "Analyzes imported and calculated membership years and creates report"
  task "nav1-2_membership_years_report": :environment do
    SacImports::MembershipYearsReport.new.create
  end

  desc "NAV1 Imports subscriptions from Navision"
  task "nav1-3_subscriptions": :setup do
    SacImports::Nav1SubscriptionsImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav1-3_subscriptions")
  end

  desc "Import people from WSO2"
  task "wso21-1_people": :setup do
    SacImports::Wso2PeopleImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "wso21-1_people")
  end

  desc "NAV2a Imports membership roles"
  task "nav2a-1_membership_roles": :setup do
    SacImports::Nav2a1RolesMembershipImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav2a1-roles-membership")
  end

  desc "NAV2a Update family main person"
  task "nav2a-2_set_family_main_person": :setup do
    SacImports::Nav2a2SetFamilyMainPerson.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav2a2-set-family-main-person")
  end

  desc "Imports families"
  task "nav2a-3_families": :setup do
    SacImports::Nav2a3FamilyImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav2a3-families")
  end

  desc "Update family addresses to be the same as the main person"
  task update_sac_family_address: :setup do
    SacImports::FamilyAddressUpdater.new.update
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "update_sac_familiy_address")
  end

  desc "NAV2b Imports missing groups"
  task "nav2b-1_missing_groups": :setup do
    SacImports::Nav2b1CreateMissingGroups.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav2b1-create-missing-groups")
  end

  desc "NAV2b Imports non-membership roles"
  task "nav2b-2_non_membership_roles": :setup do
    SacImports::Nav2b2RolesNonMembershipImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav2b2-roles-non_membership")
  end

  desc "Imports qualifications"
  task "nav3-1_qualifications": :setup do
    SacImports::Nav3QualificationsImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav3_qualifications")
  end

  desc "Imports huts"
  task "nav5-1_huts": :setup do
    SacImports::Nav5HutsImporter.new.import!
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav5-huts")
  end

  desc "Imports event kinds"
  task "nav17-1_event_kinds": :setup do
    SacImports::Nav17EventKindsImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav17-event-kinds")
  end

  desc "Imports events"
  task "nav18-1_events": :setup do
    SacImports::Nav18EventsImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav18-events")
  end

  desc "Imports event participations"
  task "nav21-1_event-participations": :setup do
    SacImports::Nav21EventParticipationsImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "nav21-event-participations")
  end

  desc "NAV1 Imports subscriptions from Navision"
  task "chimp-subscriptions": :setup do
    SacImports::ChimpImporter.new.create
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "chimp-subscriptions")
  end

  desc "Run cleanup tasks"
  task cleanup: :setup do
    SacImports::Cleanup.new.run
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "cleanup")
  end

  desc "Run data quality check"
  task check_data_quality: :setup do
    SacImports::DataQualityChecker.new.run
    Rake::Task["sac_imports:dump_database"].execute(dump_name: "data_quality_check")
  end

  task :dump_database, [:dump_name] => :environment do |t, args|
    target_dir = SacImports::CsvReport::LOG_DIR

    db_config = ActiveRecord::Base.configurations.find_db_config(Rails.env).configuration_hash
    db_name = db_config[:database]
    db_user = db_config[:username]
    db_pass = db_config[:password]

    dump_name = args[:dump_name] || "sac_imports"
    dump_file = target_dir.join("#{dump_name}_#{Time.zone.now.strftime("%Y-%m-%d-%H%M")}.dump")
    puts "\e[32mDumping DB to: #{dump_file}\e[0m"

    system("PGPASSWORD=#{db_pass} pg_dump -h localhost -U #{db_user} #{db_name} > #{dump_file}")
  end
end
