module SacCas::RolesController
  extend ActiveSupport::Concern

  prepended do
    after_destroy :resolve_household_for_neuanmeldung
  end

  private

  def resolve_household_for_neuanmeldung
    destroy_family_neuanmeldungen if family_neuanmeldungs_role?
    destroy_household if neuanmeldungs_stammsektion_role?
  end

  def neuanmeldungs_stammsektion_role?
    ::SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES.map(&:sti_name).include?(entry.type)
  end

  def family_neuanmeldungs_role?
    ::SacCas::NEUANMELDUNG_ROLES.map(&:sti_name).include?(entry.type) && entry.family?
  end

  def destroy_household
    Household.new(entry.person).destroy
  end

  def destroy_family_neuanmeldungen
    Role.where(type: SacCas::NEUANMELDUNG_ROLES.map(&:sti_name),
      person_id: family_mitglieder.pluck(:id)).destroy_all
  end

  def family_mitglieder
    Household.new(person).people
  end
end
