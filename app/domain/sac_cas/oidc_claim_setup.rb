# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::OidcClaimSetup

  extend ActiveSupport::Concern

  INFERRED_ROLE_LABLES = {
    section_functionary: Group::SektionsFunktionaere.roles,
    section_president: [Group::SektionsFunktionaere::Praesidium],
    SAC_employee: Group::Geschaeftsstelle.roles,
    SAC_management: Group::Geschaeftsleitung.roles,
    SAC_member: [Group::SektionsMitglieder::Mitglied],
    SAC_member_additional: [Group::SektionsMitglieder::MitgliedZusatzsektion],
    SAC_central_board_member: Group::Zentralvorstand.roles,
    SAC_commission_member: Group::Kommission.roles,
    SAC_tourenportal_subscriber: Group::AboTourenPortal.roles,
    section_commission_member: Group::SektionsKommission.roles,
    huts_functionary: Group::SektionsHuettenkommission.roles,
    tourenportal_author: [Group::AboTourenPortal::Autor],
    tourenportal_community: [Group::AboTourenPortal::Community],
    tourenportal_administrator: [Group::AboTourenPortal::Admin],
    magazin_subscriber: Group::AboMagazin.roles,
    section_tour_functionary: Group::SektionsTourenkommission.roles,
  }

  def run
    super

    add_claim(:picture_url, scope: [:name, :with_roles])
    add_claim(:phone, scope: [:name, :with_roles])

    add_claim(:membership_years, scope: :with_roles)
    add_claim(:user_groups, scope: :user_groups)
  end

  private

  def picture_url(owner)
    owner.decorate.picture_full_url
  end

  def phone(owner)
    owner.phone_numbers.order(:id).find_by(label: SacCas.main_phone_label)&.number
  end

  def membership_years(owner)
    Person.with_membership_years.find_by(id: owner.id).membership_years
  end

  def user_groups(owner)
    inferred_role_strings(owner) + formatted_active_roles(owner)
  end

  def inferred_role_strings(owner)
    INFERRED_ROLE_LABLES.select do |_, roles|
      (owner.roles.map(&:class) & roles).any?
    end.keys.map(&:to_s)
  end

  def formatted_active_roles(owner)
    owner.roles.map { |r| "#{r.type}##{r.group_id}" }
  end
end
