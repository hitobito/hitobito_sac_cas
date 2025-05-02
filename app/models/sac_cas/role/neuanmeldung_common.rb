module SacCas::Role::NeuanmeldungCommon
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_family_neuanmeldungen, if: :family?
  end

  def destroy_family_neuanmeldungen
    Role.where(type: SacCas::NEUANMELDUNG_ROLES.map(&:sti_name),
      person_id: family_mitglieder.pluck(:id)).destroy_all
  end

  def family_mitglieder
    Household.new(person).people
  end
end
