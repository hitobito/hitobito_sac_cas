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
    ]

    config.to_prepare do
      JobManager.wagon_jobs += [PromoteNeuanmeldungenJob]
      HitobitoLogEntry.categories += %w(neuanmeldungen)

      # extend application classes here
      Event::Kind.prepend SacCas::Event::Kind
      Event::Course.prepend SacCas::Event::Course
      Event::KindCategory.prepend SacCas::Event::KindCategory
      FutureRole.prepend SacCas::FutureRole
      Group.include SacCas::Group
      Person.include SacCas::Person
      Person::Household.prepend SacCas::Person::Household
      PeopleManager.prepend SacCas::PeopleManager
      Role.prepend SacCas::Role
      SelfRegistration.prepend SacCas::SelfRegistration
      SelfRegistration::MainPerson.prepend SacCas::SelfRegistration::MainPerson
      Roles::Termination.prepend SacCas::Roles::Termination
      Qualification.include SacCas::Qualification
      QualificationKind.include SacCas::QualificationKind

      StepsComponent.prepend SacCas::StepsComponent
      StepsComponent::ContentComponent.prepend SacCas::StepsComponent::ContentComponent
      admin = NavigationHelper::MAIN.find { |opts| opts[:label] == :admin }
      admin[:active_for] << 'event_levels'


      ## Abilities
      Ability.store.register Event::LevelAbility
      Ability.store.register CostCenterAbility
      Ability.store.register CostUnitAbility
      PeopleManagerAbility.prepend SacCas::PeopleManagerAbility
      Ability.store.register ExternalTrainingAbility
      QualificationAbility.include SacCas::QualificationAbility
      RoleAbility.prepend SacCas::RoleAbility

      ## Decorators
      RoleDecorator.prepend SacCas::RoleDecorator

      ## Domain
      Event::TrainingDays::CoursesLoader.prepend SacCas::Event::TrainingDays::CoursesLoader

      ## Resources
      GroupResource.include SacCas::GroupResource
      PersonResource.include SacCas::PersonResource
      Event::KindResource.include SacCas::Event::KindResource

      ## Helpers
      FilterNavigation::People.prepend SacCas::FilterNavigation::People
      MountedAttrs::EnumSelect.prepend SacCas::MountedAttrs::EnumSelect
      Dropdown::TableDisplays.prepend SacCas::Dropdown::TableDisplays

      admin_item = NavigationHelper::MAIN.find { |item| item[:label] == :admin }
      admin_item[:active_for] += %w(cost_centers cost_units)

      ## Controllers
      EventsController.prepend SacCas::EventsController
      Event::KindsController.prepend SacCas::Event::KindsController
      Event::KindCategoriesController.prepend SacCas::Event::KindCategoriesController
      GroupsController.permitted_attrs << :mitglied_termination_by_section_only
      Groups::SelfInscriptionController.prepend SacCas::Groups::SelfInscriptionController
      Groups::SelfRegistrationController.prepend SacCas::Groups::SelfRegistrationController
      PeopleController.prepend SacCas::PeopleController
      PeopleManagersController.prepend SacCas::PeopleManagersController
      Person::HistoryController.prepend SacCas::Person::HistoryController

      Export::PeopleExportJob.prepend SacCas::Export::PeopleExportJob

      QualificationKindsController.permitted_attrs += [:tourenchef_may_edit]
      QualificationsController.prepend SacCas::QualificationsController

      Export::Tabular::People::PeopleFull.prepend SacCas::Export::Tabular::People::PeopleFull
      [
        Export::Tabular::People::Households,
        Export::Tabular::People::ParticipationsFull,
        Export::Tabular::People::ParticipationsHouseholds,
        Export::Tabular::People::PeopleAddress,
        Export::Tabular::People::PeopleFull
      ].each { |klass| klass.prepend Export::Tabular::People::WithSacAdditions }



      TableDisplay.register_column(Person,
                                   TableDisplays::ResolvingColumn,
                                   [
                                     :membership_years,
                                     :beitragskategorie,
                                     :antrag_fuer,
                                     :antragsdatum,
                                     :beitrittsdatum,
                                     :confirmed_at,
                                     :duplicate_exists,
                                     :wiedereintritt,
                                     :self_registration_reason,
                                     :address_valid
                                   ])
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

    initializer 'sac_cas.add_oidc_claims' do |_app|
      Doorkeeper::OpenidConnect.configuration.claims[:picture_url] =
        Doorkeeper::OpenidConnect::Claims::NormalClaim.new(
          name: :picture_url,
          scope: :name,
          response: [:user_info],
          generator: Proc.new do |resource_owner|
            resource_owner.decorate.picture_full_url
          end
        )

      Doorkeeper::OpenidConnect.configuration.claims[:with_roles_picture_url] =
        Doorkeeper::OpenidConnect::Claims::NormalClaim.new(
          name: :picture_url,
          scope: :with_roles,
          response: [:user_info],
          generator: Proc.new do |resource_owner|
            resource_owner.decorate.picture_full_url
          end
        )
    end

    private

    def seed_fixtures
      fixtures = root.join('db', 'seeds')
      ENV['NO_ENV'] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end

  end
end
