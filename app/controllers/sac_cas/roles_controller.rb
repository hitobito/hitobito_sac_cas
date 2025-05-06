module SacCas::RolesController
  extend ActiveSupport::Concern

  prepended do
    after_destroy :destroy_household, if: :neuanmeldungs_role?
  end

  private

  def neuanmeldungs_role?
    ::SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES.map(&:sti_name).include?(entry.type)
  end

  def destroy_household
    Household.new(entry.person).destroy
  end
end
