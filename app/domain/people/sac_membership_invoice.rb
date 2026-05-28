# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SacMembershipInvoice
  def initialize(person)
    @person = person
  end

  # Für eine Person kann eine Mitgliedschaftsrechnung erzeugt werden, wenn
  # die Person eine Stammsektionsmitgliedschaft oder -anmeldung im aktuellen Jahr hat UND
  # (die Person die Familienhauptperson ist ODER mindestens eine
  #  individuelle Rolle hat (Beitragskategorie != "family"))
  def invoicable?
    stammsektion_role? &&
      (@person.sac_family_main_person? || individual_membership?)
  end

  private

  def stammsektion_role?
    active_roles(stammsektion_roles).exists?
  end

  def individual_membership?
    active_roles(invoicable_roles).where.not(beitragskategorie: :family).exists?
  end

  def active_roles(types)
    @person.roles.active(current_year_range).where(type: types.map(&:sti_name))
  end

  def current_year_range
    year = Date.current.year
    Date.new(year, 1, 1)..Date.new(year, 12, 31)
  end

  def stammsektion_roles
    SacCas::MITGLIED_STAMMSEKTION_ROLES +
      SacCas::NEUANMELDUNG_NV_STAMMSEKTION_ROLES
  end

  def invoicable_roles
    SacCas::MITGLIED_STAMMSEKTION_ROLES +
      SacCas::MITGLIED_ZUSATZSEKTION_ROLES +
      SacCas::NEUANMELDUNG_NV_STAMMSEKTION_ROLES +
      SacCas::NEUANMELDUNG_NV_ZUSATZSEKTION_ROLES
  end
end
