# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module HitobitoSacCas
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Set the required application version.
    app_requirement '>= 0'

    # Add a load path for this specific wagon
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
      #{config.root}/lib/hitobito_sac_cas
    ]

    config.to_prepare do
      # extend application classes here
      Group.include SacCas::Group
      Person.include SacCas::Person

      FilterNavigation::People.send :prepend, SacCas::FilterNavigation::People

      Groups::SelfRegistrationController.include SacCas::Groups::SelfRegistrationController
      PeopleController.send :prepend, SacCas::PeopleController

      [
        Export::Tabular::People::Households,
        Export::Tabular::People::ParticipationsFull,
        Export::Tabular::People::ParticipationsHouseholds,
        Export::Tabular::People::PeopleAddress,
        Export::Tabular::People::PeopleFull
      ].each { |klass| klass.prepend Export::Tabular::People::WithMembershipNumber }

      TableDisplay.register_column(Person,
                                   TableDisplays::People::MembershipYearsColumn,
                                   [:membership_years])
    end


    initializer 'sac_cas.add_settings' do |_app|
      Settings.add_source!(File.join(paths['config'].existent, 'settings.yml'))
      Settings.reload!
    end

    initializer 'sac_cas.add_inflections' do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.irregular 'beitragskategorie', 'beitragskategorien'
      end
    end

    private

    def seed_fixtures
      fixtures = root.join('db', 'seeds')
      ENV['NO_ENV'] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end

  end
end
