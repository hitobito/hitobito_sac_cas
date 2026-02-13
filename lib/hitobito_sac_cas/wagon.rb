# frozen_string_literal: true

#  Copyright (c) 2023-2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
module HitobitoSacCas
  class Wagon < Rails::Engine # rubocop:todo Metrics/ClassLength
    include Wagons::Wagon

    # Set the required application version.
    app_requirement ">= 0"

    # Add a load path for this specific wagon
    config.autoload_paths += %W[
      #{config.root}/app/abilities
      #{config.root}/app/domain
      #{config.root}/app/jobs
    ]

    if Rails.env.development?
      config.action_mailer.preview_paths = [config.root.join("spec", "mailers", "previews").to_s]

      if config.respond_to?(:view_component)
        config.view_component.preview_paths << "#{config.root}/spec/components/previews"
        config.view_component.preview_controller = "WizardsPreviewsController"
      end

      ActiveSupport::Inflector.inflections { |i| i.acronym("TTY") }
      config.autoload_paths << "#{config.root}/lib"
    end

    # We can't directly override the languages hash in a config file since the hashes are merged
    config.to_prepare do
      if Rails.env.test?
        settings = Settings.to_hash
        settings[:application][:languages] = {de: "Deutsch", fr: "Français", it: "Italiano"}
        Settings.reload_from_files(settings)
      end
    end

    config.before_initialize do |app|
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
        Qualifications::ExpirationMailerJob,
        People::CacheMembershipYearsJob,
        People::SacMemberships::DestroyHouseholdsForInactiveMembershipsJob,
        Roles::TerminateTourenleiterJob,
        Roles::TerminateStaleNeuanmeldungenNvJob,
        Invoices::Abacus::CreateYearlyAboAlpenInvoicesJob
      ]

      # only schedule BackupMitgliederScheduleJob if sftp config is present
      if Settings.sftp.config.present?
        JobManager.wagon_jobs += [Export::BackupMitgliederScheduleJob]
      end

      Doorkeeper::AuthorizationsController.prepend SacCas::Doorkeeper::AuthorizationsController

      HitobitoLogEntry.categories += %w[neuanmeldungen rechnungen stapelverarbeitung]

      MailingLists::Filter::Chain::TYPES << Person::Filter::InvoiceReceiver

      ChangelogEntry.regex_substitutions[/\b(HIT-\d+)\b/] =
        ChangelogEntry.markdown_link(label: '\1', url: 'https://saccas.atlassian.net/browse/\1')

      # extend application classes here
      Contactable::Address.prepend SacCas::Contactable::Address
      CustomContent.prepend SacCas::CustomContent
      Event.prepend SacCas::Event
      Event::Kind.prepend SacCas::Event::Kind
      Event::Course.prepend SacCas::Event::Course
      Event::KindCategory.prepend SacCas::Event::KindCategory
      Event::ParticipationBanner.prepend SacCas::Event::ParticipationBanner
      Event::ParticipationContactData.prepend SacCas::Event::ParticipationContactData
      Event::Participatable.prepend SacCas::Event::Participatable
      Event::ParticipationMailer.prepend SacCas::Event::ParticipationMailer
      Event::Participation.prepend SacCas::Event::Participation
      Event::Answer.include SacCas::Event::Answer
      Group.prepend SacPhoneNumbers
      Group.include SacCas::Group
      Household.prepend SacCas::Household
      HouseholdMember.prepend SacCas::HouseholdMember
      Households::MemberValidator.prepend SacCas::Households::MemberValidator
      MailingList.include SacCas::MailingList
      Person.prepend SacCas::Person
      Person.prepend SacPhoneNumbers
      People::Membership::Verifier.prepend SacCas::People::Membership::Verifier
      PeopleManager.prepend SacCas::PeopleManager
      PhoneNumber.include SacCas::PhoneNumber
      Role.prepend SacCas::Role
      Roles::TerminateRoleLink.prepend SacCas::Roles::TerminateRoleLink
      Qualification.include SacCas::Qualification
      QualificationKind.include SacCas::QualificationKind
      PhoneNumber.predefined_labels.each do |label|
        PeopleController.permitted_attrs << {"phone_number_#{label}_attributes": [:id, :number]}
        GroupsController.permitted_attrs << {"phone_number_#{label}_attributes": [:id, :number]}
      end

      Wizards::Base.prepend SacCas::Wizards::Base
      Wizards::Steps::NewUserForm.support_company = false

      HouseholdAsideComponent.prepend SacCas::HouseholdAsideComponent
      HouseholdAsideMemberComponent.prepend SacCas::HouseholdAsideMemberComponent

      ## Abilities
      Role::Types::Permissions <<
        :read_all_people <<
        :layer_events_full <<
        :layer_created_events_full <<
        :layer_mitglieder_full

      Role::Types::PermissionImplicationsForGroups[:layer_mitglieder_full] =
        {group_and_below_full: Group::SektionsMitglieder}

      AbilityDsl::UserContext::GROUP_PERMISSIONS << :layer_events_full
      AbilityDsl::UserContext::LAYER_PERMISSIONS << :layer_events_full

      Ability.store.register CostCenterAbility
      Ability.store.register CostUnitAbility
      Ability.store.register CourseCompensationCategoryAbility
      Ability.store.register CourseCompensationRateAbility
      Ability.store.register Event::DisciplineAbility
      Ability.store.register Event::ApprovalKindAbility
      Ability.store.register Event::FitnessRequirementAbility
      Ability.store.register Event::LevelAbility
      Ability.store.register Event::TargetGroupAbility
      Ability.store.register Event::TechnicalRequirementAbility
      Ability.store.register Event::TraitAbility
      Ability.store.register ExternalInvoiceAbility
      Ability.store.register ExternalTrainingAbility
      Ability.store.register Memberships::JoinZusatzsektionAbility
      Ability.store.register Memberships::SwitchStammsektionAbility
      Ability.store.register Memberships::UndoTerminationAbility
      Ability.store.register Memberships::ChangeZusatzsektionToFamilyAbility
      Ability.store.register SacMembershipConfigAbility
      Ability.store.register SacSectionMembershipConfigAbility
      Ability.store.register SectionOfferingAbility
      Ability.store.register TerminationReasonAbility

      Event::RoleAbility.prepend SacCas::Event::RoleAbility
      Event::ParticipationAbility.prepend SacCas::Event::ParticipationAbility
      EventAbility.prepend SacCas::EventAbility
      GroupAbility.prepend SacCas::GroupAbility
      MailingListAbility.prepend SacCas::MailingListAbility
      PersonAbility.prepend SacCas::PersonAbility
      PersonReadables.prepend SacCas::PersonReadables
      Person::AddRequestAbility.prepend SacCas::Person::AddRequestAbility
      QualificationAbility.include SacCas::QualificationAbility
      RoleAbility.prepend SacCas::RoleAbility
      SubscriptionAbility.prepend SacCas::SubscriptionAbility
      TokenAbility.prepend SacCas::TokenAbility
      VariousAbility.include SacCas::VariousAbility

      ## Decorators
      GroupDecorator.prepend SacCas::GroupDecorator
      RoleDecorator.prepend SacCas::RoleDecorator
      PersonDecorator.prepend SacCas::PersonDecorator
      Event::ParticipationDecorator.prepend SacCas::Event::ParticipationDecorator
      Event::RoleDecorator.prepend SacCas::Event::RoleDecorator
      EventDecorator.icons["Event::Tour"] = :mountain

      ## Domain
      People::UpdateAfterRoleChange.prepend SacCas::People::UpdateAfterRoleChange
      OidcClaimSetup.prepend SacCas::OidcClaimSetup
      SearchStrategies::SqlConditionBuilder.matchers.merge!(
        "people.id" => SearchStrategies::SqlConditionBuilder::IdMatcher,
        "people.birthday" => SearchStrategies::SqlConditionBuilder::BirthdayMatcher
      )
      Event::Qualifier::StartAtCalculator.prepend SacCas::Event::Qualifier::StartAtCalculator
      Event::TrainingDays::CoursesLoader.prepend SacCas::Event::TrainingDays::CoursesLoader
      SearchStrategies::PersonSearch.prepend SacCas::SearchStrategies::PersonSearch
      Synchronize::Mailchimp::Subscriber.prepend SacCas::Synchronize::Mailchimp::Subscriber

      ## Resources
      GroupResource.include SacCas::GroupResource
      PersonResource.include SacCas::PersonResource
      EventResource.include SacCas::EventResource
      RoleResource.include SacCas::RoleResource
      Event::CourseResource.include SacCas::Event::CourseResource
      Event::KindResource.include SacCas::Event::KindResource
      Person::NameResource.course_leader_roles = [Event::Role::Leader, Event::Course::Role::Leader]

      ## Helpers
      Changelogs::FooterLinkBuilder.prepend SacCas::Changelogs::FooterLinkBuilder
      ApplicationMarketHelper.prepend SacCas::ApplicationMarketHelper
      EventKindsHelper.prepend SacCas::EventKindsHelper
      EventsHelper.prepend SacCas::EventsHelper
      EventParticipationsHelper.prepend SacCas::EventParticipationsHelper
      PeopleHelper.prepend SacCas::PeopleHelper
      RolesHelper.prepend SacCas::RolesHelper
      FilterNavigation::People.prepend SacCas::FilterNavigation::People
      MountedAttrs::EnumSelect.prepend SacCas::MountedAttrs::EnumSelect
      Dropdown::PeopleExport.prepend SacCas::Dropdown::PeopleExport
      Dropdown::GroupEdit.prepend SacCas::Dropdown::GroupEdit
      Dropdown::Event::Participation::MailDispatch.prepend(
        SacCas::Dropdown::Event::Participation::MailDispatch
      )
      Event::ParticipationButtons.prepend SacCas::Event::ParticipationButtons
      Sheet::Group.prepend SacCas::Sheet::Group
      Sheet::Person.prepend SacCas::Sheet::Person
      StandardFormBuilder.prepend SacCas::StandardFormBuilder

      # Navigation
      course_index = NavigationHelper::MAIN.index { |opts| opts[:label] == :courses }
      NavigationHelper::MAIN.insert(
        course_index,
        label: :tours,
        icon_name: :mountain,
        url: :list_tours_path,
        active_for: %w[list_tours],
        if: lambda do |_|
          MountedAttribute.exists?(key: "tours_enabled",
            value: true) && can?(:list_available, Event::Tour)
        end
      )

      admin_item = NavigationHelper::MAIN.find { |item| item[:label] == :admin }
      admin_item[:active_for] += %w[
        cost_centers
        cost_units
        event_approval_kinds
        event_disciplines
        event_levels
        event_target_groups
        event_technical_requirements
        event_fitness_requirements
        event_traits
        event_approval_kinds
        termination_reasons
        section_offerings
        course_compensation_categories
        course_compensation_rates
      ]

      ## Controllers
      ApplicationController.include BasicAuth if Settings.basic_auth
      Devise::Hitobito::SessionsController.prepend SacCas::Devise::Hitobito::SessionsController

      ApplicationController.prepend SacCas::ApplicationController
      ChangelogController.prepend SacCas::ChangelogController
      EventsController.prepend SacCas::EventsController
      Event::ApplicationMarketController.prepend SacCas::Event::ApplicationMarketController
      Event::KindsController.prepend SacCas::Event::KindsController
      Event::KindCategoriesController.prepend SacCas::Event::KindCategoriesController
      Event::ListsController.prepend SacCas::Event::ListsController
      Event::ParticipationsController.prepend SacCas::Event::ParticipationsController
      Event::Participations::MailDispatchesController.prepend(
        SacCas::Event::Participations::MailDispatchesController
      )
      Event::RegisterController.prepend SacCas::Event::RegisterController
      Event::RolesController.prepend SacCas::Event::RolesController
      GroupsController.prepend SacCas::GroupsController
      Groups::SelfRegistrationController.prepend SacCas::Groups::SelfRegistrationController
      Groups::SelfInscriptionController.prepend SacCas::Groups::SelfInscriptionController
      JsonApi::EventsController.prepend SacCas::JsonApi::EventsController
      JsonApi::PeopleController.prepend SacCas::JsonApi::PeopleController

      PeopleController.prepend SacCas::PeopleController
      Person::HistoryController.prepend SacCas::Person::HistoryController
      Person::SubscriptionsController.prepend SacCas::Person::SubscriptionsController
      Person::QueryController.prepend SacCas::Person::QueryController
      Person::QueryHouseholdController.prepend SacCas::Person::QueryHouseholdController
      RolesController.prepend SacCas::RolesController

      QualificationKindsController.permitted_attrs += [:tourenchef_may_edit]
      QualificationsController.prepend SacCas::QualificationsController

      SubscriptionsController.prepend SacCas::SubscriptionsController

      People::Membership::VerifyController.include Localizable

      ## Jobs
      # configured zips (INT) total to 1337 people, adjust batch to 251 from 1000
      AddressSynchronizationJob.batch_size = 250 # default 1000
      Event::ParticipationConfirmationJob.prepend SacCas::Event::ParticipationConfirmationJob
      Export::PeopleExportJob.prepend SacCas::Export::PeopleExportJob
      Export::SubscriptionsJob.prepend SacCas::Export::SubscriptionsJob
      Export::EventParticipationsExportJob.prepend SacCas::Export::EventParticipationsExportJob

      ## Tabulars
      Export::Tabular::People::PeopleFull.prepend SacCas::Export::Tabular::People::PeopleFull
      Export::Tabular::People::PersonRow.prepend SacCas::Export::Tabular::People::PersonRow
      [
        Export::Tabular::People::Households,
        Export::Tabular::People::PeopleAddress,
        Export::Tabular::People::PeopleFull
      ].each { |klass| klass.prepend Export::Tabular::People::WithSacAdditions }

      TableDisplay.register_column(Person,
        TableDisplays::PublicColumn,
        [:data_quality, :id, :advertising])

      TableDisplay.register_column(Person,
        TableDisplays::People::BeitragskategorieColumn,
        :beitragskategorie)

      TableDisplay.register_column(Person,
        TableDisplays::People::MembershipYearsColumn,
        :membership_years)

      TableDisplay.register_column(Person,
        TableDisplays::People::AntragFuerColumn,
        :antrag_fuer)

      TableDisplay.register_column(Person,
        TableDisplays::People::AntragsdatumColumn,
        :antragsdatum)

      TableDisplay.register_column(Person,
        TableDisplays::People::BeitrittsdatumColumn,
        :beitrittsdatum)

      TableDisplay.register_column(Person,
        TableDisplays::People::ConfirmedAtColumn,
        :confirmed_at)

      TableDisplay.register_column(Person,
        TableDisplays::People::DuplicateExistsColumn,
        :duplicate_exists)

      TableDisplay.register_column(Person,
        TableDisplays::People::WiedereintrittColumn,
        :wiedereintritt)

      TableDisplay.register_column(Person,
        TableDisplays::People::SelfRegistrationReasonColumn,
        :self_registration_reason)

      TableDisplay.register_column(Person,
        TableDisplays::People::AddressValidColumn,
        :address_valid)

      TableDisplay.register_column(Person,
        TableDisplays::People::SacRemarkSectionColumn,
        [:sac_remark_section_1,
          :sac_remark_section_2,
          :sac_remark_section_3,
          :sac_remark_section_4,
          :sac_remark_section_5])

      TableDisplay.register_column(Person,
        TableDisplays::People::SacRemarkNationalOfficeColumn,
        [:sac_remark_national_office])

      TableDisplay.register_column(Person,
        TableDisplays::People::TerminateOnColumn,
        [:terminate_on])

      TableDisplay.register_column(Person,
        TableDisplays::People::TerminationReasonColumn,
        [:termination_reason])

      TableDisplay.register_column(Event::Participation,
        TableDisplays::PolymorphicShowFullColumn,
        [:invoice_state])

      TableDisplays::People::LoginStatusColumn.prepend(
        SacCas::TableDisplays::People::LoginStatusColumn
      )
      TableDisplays::ShowDetailsColumn.prepend(TableDisplays::People::SektionMemberAdminVisible)
      TableDisplays::PublicColumn.prepend(TableDisplays::People::SektionMemberAdminVisible)

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
