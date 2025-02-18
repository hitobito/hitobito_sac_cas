# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::OidcClaimSetup
  extend ActiveSupport::Concern

  INFERRED_ROLE_LABELS = {
    section_functionary: Group::SektionsFunktionaere.roles,
    section_president: [Group::SektionsFunktionaere::Praesidium],
    SAC_employee: Group::Geschaeftsstelle.roles,
    SAC_management: Group::Geschaeftsleitung.roles,
    SAC_member: [Group::SektionsMitglieder::Mitglied],
    SAC_member_additional: [Group::SektionsMitglieder::MitgliedZusatzsektion],
    SAC_central_board_member: Group::Zentralvorstand.roles,
    SAC_commission_member: Group::Kommission.roles,
    SAC_tourenportal_subscriber: Group::AboTourenPortal.roles,
    section_commission_member: Group::SektionsKommissionen.child_types.flat_map(&:role_types),
    huts_functionary: [
      *Group::SektionsClubhuette.roles,
      *Group::Sektionshuette.roles,
      Group::SektionsFunktionaere::Huettenobmann
    ],
    tourenportal_author: [Group::AboTourenPortal::Autor],
    tourenportal_community: [Group::AboTourenPortal::Community],
    tourenportal_administrator: [Group::AboTourenPortal::Admin],
    tourenportal_gratisabonnent: [Group::AboTourenPortal::Gratisabonnent],
    magazin_subscriber: Group::AboMagazin.roles,
    section_tour_functionary: [
      Group::SektionsTourenUndKurse::JsCoach,
      Group::SektionsTourenUndKurse::JoChef,
      Group::SektionsTourenUndKurse::Tourenleiter,
      Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation,
      *Group::SektionsTourenUndKurse.child_types.map do |type|
        type.const_get :Tourenchef if type.const_defined? :Tourenchef
      end
    ]
  }

  def run
    super

    with_options(scope: [:name, :with_roles]) do
      add_claim(:picture_url)
      add_claim(:membership_verify_url)
      add_claim(:phone_number_landline)
      add_claim(:phone_number_mobile)
    end

    add_claim(:membership_years, scope: :with_roles)
    add_claim(:user_groups, scope: :user_groups)
  end

  private

  def picture_url(owner)
    owner.decorate.picture_full_url
  end

  def membership_verify_url(owner)
    People::Membership::VerificationQrCode.new(owner).verify_url if owner.sac_membership_anytime?
  end

  def phone_number_landline(owner) = owner.phone_number_landline&.number

  def phone_number_mobile(owner) = owner.phone_number_mobile&.number

  def membership_years(owner)
    owner.membership_years
  end

  def user_groups(owner)
    inferred_role_strings(owner) + formatted_active_roles(owner)
  end

  def inferred_role_strings(owner)
    INFERRED_ROLE_LABELS.select do |_, roles|
      (owner.roles.map(&:class) & roles).any?
    end.keys.map(&:to_s)
  end

  def formatted_active_roles(owner)
    owner.roles.map { |r| "#{r.type}##{r.group_id}" }
  end
end
