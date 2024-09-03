# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacMembership
  def initialize(person, date: nil, in_memory: false)
    @person = person
    @date = date
    @in_memory = in_memory
  end

  def active?
    stammsektion_role.present?
  end

  def terminated?
    stammsektion_role&.terminated?
  end

  # checks for any active membership roles
  def active_in?(sac_section)
    @person.roles.exists?(group_id: sac_section.children,
      type: mitglied_types)
  end

  # checkes for active and also approvabable (neuanmeldung) roles
  def active_or_approvable_in?(sac_section)
    @person.roles.exists?(group_id: sac_section.children,
      type: mitglied_and_neuanmeldung_types)
  end

  def anytime?
    stammsektion_role.present? || any_future_role? || any_past_role?
  end

  def stammsektion
    stammsektion_role&.layer_group
  end

  def stammsektion_role
    active_roles_of_type(mitglied_stammsektion_types).first
  end

  def zusatzsektion_roles
    active_roles_of_type(mitglied_zusatzsektion_types)
  end

  def select_currently_paying(roles)
    roles.compact.select { |role| paying_person?(role.beitragskategorie) }
  end

  def future_stammsektion_roles
    @person.roles.future.where(type: mitglied_stammsektion_types)
  end

  def neuanmeldung_stammsektion_role
    active_roles_of_type(neuanmeldung_stammsektion_types).first
  end

  def neuanmeldung_nv_stammsektion_roles
    active_roles_of_type(neuanmeldung_nv_stammsektion_types)
  end

  def neuanmeldung_zusatzsektion_roles
    active_roles_of_type(neuanmeldung_zusatzsektion_types)
  end

  def neuanmeldung_nv_zusatzsektion_roles
    active_roles_of_type(neuanmeldung_nv_zusatzsektion_types)
  end

  # Here for documentation purposes only as there is no such thing as future zusatzsektion roles.
  # If this changes in the future, future_zusatzsektion_roles must be handled in
  # `Memberships::FamilyMutation` as well.
  def future_zusatzsektion_roles
    raise "there is no such thing as future zusatzsektion roles"
  end

  def sac_ehrenmitglied?
    active_roles_of_type(Group::Ehrenmitglieder::Ehrenmitglied.sti_name).present?
  end

  def sektion_ehrenmitglied?(sektion)
    active_roles_of_type(Group::SektionsMitglieder::Ehrenmitglied.sti_name)
      .any? { |r| r.layer_group.id == sektion.id }
  end

  def sektion_beguenstigt?(sektion)
    active_roles_of_type(Group::SektionsMitglieder::Beguenstigt.sti_name)
      .any? { |r| r.layer_group.id == sektion.id }
  end

  # Für eine Person kann eine Mitgliedschaftsrechnung erzeugt werden, wenn
  # die Person eine Stammsektionsmitgliedschaft oder -anmeldung hat UND
  # (die Person die Familienhauptperson ist ODER mindestens eine
  #  individuelle Rolle hat (Beitragskategorie != "family"))
  def invoice?
    (stammsektion_role.present? || neuanmeldung_nv_stammsektion_roles.present?) &&
      (@person.sac_family_main_person? || individual_membership?)
  end

  def family?
    stammsektion_role&.beitragskategorie&.family? || false
  end

  def family_id
    return unless family?

    @person.household_key.start_with?("F") ? @person.household_key : "F#{@person.household_key}"
  end

  private

  def individual_membership?
    if in_memory?
      invoicable_roles.any? { |r| !r.beitragskategorie.family? }
    else
      invoicable_roles.where.not(beitragskategorie: :family).exists?
    end
  end

  def invoicable_roles
    active_roles_of_type(invoicable_types)
  end

  def active_roles
    @person.roles.active(@date || Date.current)
    # if @date
    #   if in_memory?
    #     @person.roles.select { |r| r.active_period.cover?(@date) }
    #   else
    #     # unscope the default scope first with `with_inactive`, then get `active` for `@date`
    #     @person.roles.with_inactive.active(@date)
    #   end
    # else
    #   @person.roles
    # end
  end

  def active_roles_of_type(types)
    if in_memory?
      types = Array(types)
      active_roles.select { |r| types.include?(r.type) }
    else
      active_roles.where(type: types)
    end
  end

  def in_memory?
    @in_memory || !@person.roles.is_a?(ActiveRecord::Relation)
  end

  def any_future_role?
    @person.roles.future.where(type: mitglied_stammsektion_types).exists?
  end

  def any_past_role?
    @person.roles.ended.where(type: mitglied_stammsektion_types).exists?
  end

  def paying_person?(beitragskategorie)
    !beitragskategorie.family? || @person.sac_family_main_person?
  end

  def mitglied_types = SacCas::MITGLIED_ROLES.map(&:sti_name)

  def mitglied_stammsektion_types = SacCas::MITGLIED_STAMMSEKTION_ROLES.map(&:sti_name)

  def mitglied_zusatzsektion_types = SacCas::MITGLIED_ZUSATZSEKTION_ROLES.map(&:sti_name)

  def mitglied_and_neuanmeldung_types = SacCas::MITGLIED_AND_NEUANMELDUNG_ROLES.map(&:sti_name)

  def neuanmeldung_stammsektion_types = SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES.map(&:sti_name)

  def neuanmeldung_nv_stammsektion_types = SacCas::NEUANMELDUNG_NV_STAMMSEKTION_ROLES.map(&:sti_name)

  def neuanmeldung_zusatzsektion_types = SacCas::NEUANMELDUNG_ZUSATZSEKTION_ROLES.map(&:sti_name)

  def neuanmeldung_nv_zusatzsektion_types = SacCas::NEUANMELDUNG_NV_ZUSATZSEKTION_ROLES.map(&:sti_name)

  def invoicable_types
    mitglied_stammsektion_types +
      mitglied_zusatzsektion_types +
      neuanmeldung_nv_stammsektion_types +
      neuanmeldung_nv_zusatzsektion_types
  end
end
