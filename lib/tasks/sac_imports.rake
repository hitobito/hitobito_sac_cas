# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :sac_imports do
  def skip_existing? = ["1", "true"].exclude?(ENV["REIMPORT_ALL"].to_s.downcase)

  def default_files = {huts: "tmp/xlsx/huetten_beziehungen.xlsx"}

  desc "Imports SAC Sections"
  task "nav6-1_sac_section": [:environment] do
    SacImports::SacSectionsImporter.new.create
  end

  desc "Imports people and companies from Navision"
  task "nav1-1_people": [:environment] do
    SacImports::PeopleImporter.new.create
  end

  desc "Analyzes imported and calculated membership years and creates report"
  task "nav1-2_membership_years_report": [:environment] do
    SacImports::MembershipYearsReport.new.create
  end

  desc "Import people from WSO2"
  task "wso21-1_people": [:environment] do
    SacImports::Wso2PeopleImporter.new.create
  end

  desc "Imports membership roles"
  task "nav2-1_membership_roles": [:environment] do
    SacImports::RolesImporter.new(role_type: :membership).create
  end

  desc "Imports qualifications"
  task "nav3-1_qualifications": [:environment] do
    SacImports::QualificationsImporter.new.create
  end

  desc "Imports huts (options: FILE=#{default_files[:huts]})"
  task "nav5-1_huts": [:environment] do
    SacImports::HutsImporter.new(read_file(:huts)).import!
  end

  desc "Imports Austrittsgründe"
  task "nav8-1_austrittsgruende": [:environment] do
    raise "Not implemented"
  end

  def read_file(kind)
    Pathname(ENV["FILE"].presence || Rails.root.join(default_files.fetch(kind)))
  end
end
