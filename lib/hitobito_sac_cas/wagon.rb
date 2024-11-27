# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
module HitobitoSacCas
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Set the required application version.
    app_requirement ">= 0"

    # Add a load path for this specific wagon
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
    ]

    if Rails.env.development? && config.respond_to?(:view_component)
      config.view_component.preview_paths << "#{config.root}/spec/components/previews"
      config.view_component.preview_controller = "WizardsPreviewsController"
    end

    config.before_initialize do |_app|
      Settings.add_source!(File.join(paths["config"].existent, "settings.yml"))
      Settings.add_source!(File.join(paths["config"].existent, "settings.local.yml"))
      Settings.add_source!(File.join(paths["config"].existent, "settings", "#{Rails.env}.yml"))
      Settings.reload!
    end

    config.to_prepare do # rubocop:disable Metrics/BlockLength
      JobManager.wagon_jobs += [
        Event::CloseApplicationsJob,
        Event::ParticipantReminderJob,
        Event::LeaderReminderJob,
        Export::BackupMitgliederScheduleJob,
        PromoteNeuanmeldungenJob,
        Qualifications::ExpirationMailerJob,
        Roles::TerminateTourenleiterJob
      ]
      HitobitoLogEntry.categories += %w[neuanmeldungen rechnungen stapelverarbeitung]

      MailingLists::Filter::Chain::TYPES << Person::Filter::InvoiceReceiver

      # extend application classes here
      CustomContent.prepend SacCas::CustomContent
      Event.prepend SacCas::Event
      Event::Kind.prepend SacCas::Event::Kind
      Event::Course.prepend SacCas::Event::Course
      Event::KindCategory.prepend SacCas::Event::KindCategory
      Event::Participation.prepend SacCas::Event::Participation
      Event::ParticipationBanner.prepend SacCas::Event::ParticipationBanner
      Event::ParticipationContactData.prepend SacCas::Event::ParticipationContactData
      Event::Participatable.prepend SacCas::Event::Participatable
      Event::ParticipationMailer.prepend SacCas::Event::ParticipationMailer
      Event::Answer.include SacCas::Event::Answer
      Group.include SacCas::Group
      Household.prepend SacCas::Household
      HouseholdMember.prepend SacCas::HouseholdMember
      Households::MemberValidator.prepend SacCas::Households::MemberValidator
      Person.prepend SacCas::Person
      Person::Address.prepend SacCas::Person::Address
      People::Membership::Verifier.prepend SacCas::People::Membership::Verifier
      PeopleManager.prepend SacCas::PeopleManager
      PhoneNumber.include SacCas::PhoneNumber
      Role.prepend SacCas::Role
      Roles::TerminateRoleLink.prepend SacCas::Roles::TerminateRoleLink
      Qualification.include SacCas::Qualification
      QualificationKind.include SacCas::QualificationKind
      Contactable.prepend SacCas::Contactable
      Wizards::Steps::NewUserForm.support_company = false
      Wizards::RegisterNewUserWizard.delegate :email, to: :new_user_form

      HouseholdAsideComponent.prepend SacCas::HouseholdAsideComponent
      HouseholdAsideMemberComponent.prepend SacCas::HouseholdAsideMemberComponent

      ## Abilities
      Role::Types::Permissions << :read_all_people
      Ability.prepend SacCas::Ability
      Ability.store.register Event::LevelAbility
      Ability.store.register CostCenterAbility
      Ability.store.register CostUnitAbility
      Ability.store.register ExternalInvoiceAbility
      Ability.store.register ExternalTrainingAbility
      Ability.store.register SacMembershipConfigAbility
      Ability.store.register SacSectionMembershipConfigAbility
      Ability.store.register CourseCompensationRateAbility
      Ability.store.register CourseCompensationCategoryAbility
      Ability.store.register TerminationReasonAbility
      Ability.store.register Memberships::JoinZusatzsektionAbility
      Ability.store.register Memberships::SwitchStammsektionAbility
      Ability.store.register Memberships::TerminateSacMembershipWizardAbility
      Event::RoleAbility.prepend SacCas::Event::RoleAbility
      Event::ParticipationAbility.prepend SacCas::Event::ParticipationAbility
      GroupAbility.prepend SacCas::GroupAbility
      PersonAbility.prepend SacCas::PersonAbility
      PersonReadables.prepend SacCas::PersonReadables
      QualificationAbility.include SacCas::QualificationAbility
      RoleAbility.prepend SacCas::RoleAbility
      TokenAbility.prepend SacCas::TokenAbility
      VariousAbility.include SacCas::VariousAbility

      ## Decorators
      GroupDecorator.prepend SacCas::GroupDecorator
      RoleDecorator.prepend SacCas::RoleDecorator
      PersonDecorator.prepend SacCas::PersonDecorator
      Event::ParticipationDecorator.prepend SacCas::Event::ParticipationDecorator
      Event::RoleDecorator.prepend SacCas::Event::RoleDecorator

      ## Domain
      People::UpdateAfterRoleChange.prepend SacCas::People::UpdateAfterRoleChange
      OidcClaimSetup.prepend SacCas::OidcClaimSetup
      SearchStrategies::SqlConditionBuilder.matchers.merge!(
        "people.id" => SearchStrategies::SqlConditionBuilder::IdMatcher,
        "people.birthday" => SearchStrategies::SqlConditionBuilder::BirthdayMatcher
      )
      Event::ParticipantAssigner.prepend SacCas::Event::ParticipantAssigner
      Event::TrainingDays::CoursesLoader.prepend SacCas::Event::TrainingDays::CoursesLoader
      SearchStrategies::PersonSearch.prepend SacCas::SearchStrategies::PersonSearch

      ## Resources
      GroupResource.include SacCas::GroupResource
      PersonResource.include SacCas::PersonResource
      EventResource.include SacCas::EventResource
      Event::CourseResource.include SacCas::Event::CourseResource
      Event::KindResource.include SacCas::Event::KindResource
      Person::NameResource.course_leader_role = Event::Course::Role::Leader

      ## Helpers
      EventKindsHelper.prepend SacCas::EventKindsHelper
      EventsHelper.prepend SacCas::EventsHelper
      EventParticipationsHelper.prepend SacCas::EventParticipationsHelper
      PeopleHelper.prepend SacCas::PeopleHelper
      FilterNavigation::People.prepend SacCas::FilterNavigation::People
      MountedAttrs::EnumSelect.prepend SacCas::MountedAttrs::EnumSelect
      Dropdown::PeopleExport.prepend SacCas::Dropdown::PeopleExport
      Dropdown::TableDisplays.prepend SacCas::Dropdown::TableDisplays
      Dropdown::GroupEdit.prepend SacCas::Dropdown::GroupEdit
      Event::ParticipationButtons.prepend SacCas::Event::ParticipationButtons
      Sheet::Person.prepend SacCas::Sheet::Person
      StandardFormBuilder.prepend SacCas::StandardFormBuilder

      admin_item = NavigationHelper::MAIN.find { |item| item[:label] == :admin }
      admin_item[:active_for] += %w[cost_centers cost_units event_levels termination_reasons course_compensation_categories course_compensation_rates]

      ## Controllers
      ApplicationController.include BasicAuth if Settings.basic_auth

      ApplicationController.prepend SacCas::ApplicationController
      EventsController.prepend SacCas::EventsController
      Event::ApplicationMarketController.prepend SacCas::Event::ApplicationMarketController
      Event::KindsController.prepend SacCas::Event::KindsController
      Event::KindCategoriesController.prepend SacCas::Event::KindCategoriesController
      Event::ParticipationsController.prepend SacCas::Event::ParticipationsController
      Event::RolesController.prepend SacCas::Event::RolesController
      GroupsController.permitted_attrs << :mitglied_termination_by_section_only
      Groups::SelfRegistrationController.prepend SacCas::Groups::SelfRegistrationController
      MailingListsController.prepend SacCas::MailingListsController
      PeopleController.permitted_attrs << :correspondence
      PeopleController.prepend SacCas::PeopleController
      Person::HistoryController.prepend SacCas::Person::HistoryController
      Person::QueryController.prepend SacCas::Person::QueryController
      Person::QueryHouseholdController.prepend SacCas::Person::QueryHouseholdController
      Subscriber::FilterController.prepend SacCas::Subscriber::FilterController

      QualificationKindsController.permitted_attrs += [:tourenchef_may_edit]
      QualificationsController.prepend SacCas::QualificationsController

      SubscriptionsController.prepend SacCas::SubscriptionsController

      People::Membership::VerifyController.include Localizable

      ## Jobs
      Event::ParticipationConfirmationJob.prepend SacCas::Event::ParticipationConfirmationJob
      Export::PeopleExportJob.prepend SacCas::Export::PeopleExportJob
      Export::SubscriptionsJob.prepend SacCas::Export::SubscriptionsJob

      ## Tabulars
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
          :address_valid,
          :data_quality,
          :sac_remark_national_office,
          :sac_remark_section_1,
          :sac_remark_section_2,
          :sac_remark_section_3,
          :sac_remark_section_4,
          :sac_remark_section_5
        ])

      TableDisplay.register_column(Event::Participation,
        TableDisplays::ShowFullColumn,
        [:invoice_state])

      Synchronize::Mailchimp::Synchronizator.member_fields = [
        [:language, ->(p) { p.language }]
      ]

      Wizards::Base.class_attribute :asides, default: []
    end

    initializer "sac_cas.add_inflections" do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.irregular "beitragskategorie", "beitragskategorien"
      end
    end

    initializer "sac_cas.append_doorkeeper_scope" do |_app|
      Doorkeeper.configuration.scopes.add "user_groups"
    end

    private

    def seed_fixtures
      fixtures = root.join("db", "seeds")
      ENV["NO_ENV"] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end
  end
end
