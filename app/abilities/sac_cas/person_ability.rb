# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club.
#  This file is part of hitobito_sac_cas and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonAbility
  extend ActiveSupport::Concern

  prepended do
    on(Person) do
      class_side(:create_households).if_backoffice
      permission(:read_all_people)
        .may(:read_all_people, :show)
        .everybody
      permission(:read_all_people)
        .may(:history, :show_details, :show_full, :index_notes, :log, :security)
        .if_backoffice

      permission(:layer_and_below_full)
        # rubocop:todo Layout/LineLength
        .may(:index_external_invoices, :create_membership_invoice, :create_abo_magazin_invoice, :cancel_external_invoice, :security)
        # rubocop:enable Layout/LineLength
        .if_backoffice
      permission(:any).may(:index_invoices, :security).none
      permission(:any)
        .may(:set_sac_family_main_person)
        .if_person_is_adult_and_has_email_and_all_household_members_writable
      permission(:any).may(:show_remarks).if_backoffice_or_functionary
      permission(:any).may(:manage_national_office_remark).if_backoffice
      permission(:any).may(:manage_section_remarks).if_backoffice_or_functionary
      permission(:any).may(:log).if_backoffice_or_backoffice_readonly
    end
  end

  def if_any_writing_permissions
    writing_permissions = [:group_full, :group_and_below_full,
      :layer_full, :layer_and_below_full, :layer_events_full]
    contains_any?(writing_permissions, user_context.all_permissions)
  end

  def if_backoffice_or_functionary
    if_backoffice || if_section_functionary
  end

  def if_backoffice_or_backoffice_readonly
    if_backoffice || role_type?(::Group::Geschaeftsstelle::MitarbeiterLesend)
  end

  def if_backoffice
    role_type?(*SacCas::SAC_BACKOFFICE_ROLES)
  end

  def if_section_functionary
    role_type?(*SacCas::SAC_SECTION_FUNCTIONARY_ROLES)
  end

  def if_person_is_adult_and_has_email_and_all_household_members_writable
    return false unless person.household.exists?
    return false unless person.adult?
    return false if person.email.blank?

    [person, *person.household_people].all? do |household_person|
      can_update_household_person?(household_person)
    end
  end

  def can_update_household_person?(household_person)
    Ability.new(user).can?(:update, household_person)
  end
end
