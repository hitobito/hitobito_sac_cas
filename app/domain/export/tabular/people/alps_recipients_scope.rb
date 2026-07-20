# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class AlpsRecipientsScope
    # depends on what is required for the tabular attributes in AlpsRecipients
    SELECTED_COLUMNS = %w[
      id
      last_name
      first_name
      company_name
      street
      housenumber
      address_care_of
      postbox
      country
      zip_code
      town
      language
      birthday
      company
    ].freeze

    attr_reader :reference_date, :new_entries_from

    def initialize(reference_date, new_entries_from)
      @reference_date = reference_date
      @new_entries_from = new_entries_from
    end

    def regular(lang)
      scope = base_scope.where(language_condition(lang, abonnent_group_ids.fetch(lang)))
      if lang == :de
        scope = scope.where("people.country IS NULL OR people.country <> 'DE'")
      end
      if new_entries_from
        scope = scope.where.not(people: {id: new_entries(lang).pluck("people.id")})
      end
      scope.includes(:roles_unscoped)
    end

    def germany
      base_scope
        .where(language_condition(:de, abonnent_group_ids.fetch(:de)))
        .where("people.country = 'DE'")
        .includes(:roles_unscoped)
    end

    def new_entries(lang)
      base_scope
        .where(new_entries_condition(lang, abonnent_group_ids.fetch(lang)))
        .where("people.country = 'CH'")
        .includes(:roles_unscoped)
    end

    def all
      # do preload to get all roles for correct entry_on date
      base_scope.preload(:roles_unscoped)
    end

    def abonnent_group_ids
      @abonnent_group_ids ||= begin
        groups = Group::AboMagazin.all
        [:de, :fr, :it].index_with do |lang|
          suffix = lang.to_s
          group = groups.find do |g|
            name = g.name.downcase
            name.end_with?(suffix) || name.end_with?(suffix.first)
          end
          raise "Could not find AboMagazin group for language #{suffix.upcase}" unless group
          group.id
        end
      end
    end

    private

    def base_scope
      Person
        .joins(:roles_unscoped)
        .select(SELECTED_COLUMNS)
        .left_joins(:subscriptions)
        .merge(Role.active(reference_date))
        .where(*mitglied_or_abonnent_condition)
        .order(:id)
        .distinct
    end

    def mitglied_or_abonnent_condition
      [
        <<-SQL.squish,
          (roles.type = :mitglied_type AND
           (roles.beitragskategorie <> :beitragskategorie OR people.sac_family_main_person) AND
           NOT people.id IN (:excluded_from_mailing_list)) OR
          roles.type IN (:abonnent_types)
        SQL
        mitglied_type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name),
        beitragskategorie: SacCas::Beitragskategorie::Calculator::CATEGORY_FAMILY,
        excluded_from_mailing_list:,
        abonnent_types: SacCas::ABONNENT_MAGAZIN_ROLES.map(&:sti_name)
      ]
    end

    def excluded_from_mailing_list
      Subscription
        .where(
          mailing_list_id: sac_magazine_mailing_list_id,
          excluded: true,
          subscriber_type: "Person"
        )
        .select(:subscriber_id)
    end

    def language_condition(lang, abo_group_ids)
      [
        <<-SQL.squish,
          (roles.type = :mitglied_type AND
           people.language = :lang) OR
          roles.group_id IN (:abo_group_ids)
        SQL
        mitglied_type: SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name),
        lang:,
        abo_group_ids:
      ]
    end

    def new_entries_condition(lang, abo_group_ids)
      # using pluck is a lot more performant than using this query as a subquery,
      # also especially because the main query is processed in batches in the export jobs,
      # multiplying the saved time by the number of batches.
      new_mitglieder_ids = eintritte_scope(SacCas::MITGLIED_STAMMSEKTION_ROLES).pluck(:person_id)
      new_abonnenten_ids = eintritte_scope(SacCas::ABONNENT_MAGAZIN_ROLES)
        .where(roles: {group_id: abo_group_ids})
        .pluck(:person_id)

      [
        <<-SQL.squish,
          (people.language = :lang AND
           people.id IN (:new_mitglieder_ids)) OR
          people.id IN (:new_abonnenten_ids)
        SQL
        lang:,
        new_mitglieder_ids:,
        new_abonnenten_ids:
      ]
    end

    def eintritte_scope(types)
      Export::Tabular::People::EintritteScope
        .new(new_entries_from..reference_date, relevant_role_types: types)
        .roles
    end

    def sac_magazine_mailing_list_id
      @sac_magazine_mailing_list_id ||=
        MailingList.find_by(internal_key: SacCas::MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY).id
    end
  end
end
