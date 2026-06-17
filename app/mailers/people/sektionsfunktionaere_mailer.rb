# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::SektionsfunktionaereMailer < ApplicationMailer
  include CommonMailerPlaceholders

  ONBOARDING_PRAESIDIUM = "sektions_funktionaere_onboarding_praesidium"
  ONBOARDING_MITGLIEDERVERWALTUNG = "sektions_funktionaere_onboarding_mitgliederverwaltung"
  ONBOARDING_ADMINISTRATION = "sektions_funktionaere_onboarding_administration"
  ONBOARDING_REDAKTION = "sektions_funktionaere_onboarding_redaktion"
  ONBOARDING_KULTURBEAUFTRAGTER = "sektions_funktionaere_onboarding_kulturbeauftragter"
  ONBOARDING_UMWELTBEAUFTRAGTER = "sektions_funktionaere_onboarding_umweltbeauftragter"
  ONBOARDING_TOURENCHEF = "sektions_funktionaere_onboarding_tourenchef"
  ONBOARDING_TOURENLEITER = "sektions_funktionaere_onboarding_tourenleiter"
  ONBOARDING_KIBE_CHEF = "sektions_funktionaere_onboarding_kibe_chef"
  ONBOARDING_FABE_CHEF = "sektions_funktionaere_onboarding_fabe_chef"
  ONBOARDING_JO_CHEF = "sektions_funktionaere_onboarding_jo_chef"
  ONBOARDING_HUETTENOBMANN = "sektions_funktionaere_onboarding_huettenobmann"
  ONBOARDING_HUETTENCHEF = "sektions_funktionaere_onboarding_huettenchef"
  ONBOARDING_HUETTENWART = "sektions_funktionaere_onboarding_huettenwart"

  def praesidium_onboarding(role)
    send_mail(role, ONBOARDING_PRAESIDIUM, SacCas::MV_EMAIL)
  end
  alias_method :co_praesidium_onboarding, :praesidium_onboarding
  alias_method :vize_praesidium_onboarding, :praesidium_onboarding
  alias_method :praesidium_ortsgruppe_onboarding, :praesidium_onboarding
  alias_method :co_praesidium_ortsgruppe_onboarding, :praesidium_onboarding
  alias_method :vize_praesidium_ortsgruppe_onboarding, :praesidium_onboarding

  def mitgliederverwaltung_onboarding(role)
    send_mail(role, ONBOARDING_MITGLIEDERVERWALTUNG, SacCas::MV_EMAIL)
  end

  def administration_onboarding(role)
    send_mail(role, ONBOARDING_ADMINISTRATION, SacCas::MV_EMAIL)
  end

  def redaktion_onboarding(role)
    send_mail(role, ONBOARDING_REDAKTION, SacCas::MV_EMAIL)
  end

  def kulturbeauftragter_onboarding(role)
    send_mail(role, ONBOARDING_KULTURBEAUFTRAGTER, SacCas::MV_EMAIL)
  end

  def umweltbeauftragter_onboarding(role)
    send_mail(role, ONBOARDING_UMWELTBEAUFTRAGTER, SacCas::MV_EMAIL)
  end

  def huettenobmann_onboarding(role)
    send_mail(role, ONBOARDING_HUETTENOBMANN, SacCas::HUETTEN_EMAIL)
  end

  def tourenchef_onboarding(role)
    send_mail(role, ONBOARDING_TOURENCHEF, Group.root.course_admin_email)
  end
  alias_method :tourenchef_sommer_onboarding, :tourenchef_onboarding
  alias_method :tourenchef_winter_onboarding, :tourenchef_onboarding

  def tourenleiter_onboarding(role)
    send_mail(role, ONBOARDING_TOURENLEITER, Group.root.course_admin_email)
  end
  alias_method :tourenleiter_ohne_qualifikation_onboarding, :tourenleiter_onboarding

  def kibe_chef_onboarding(role)
    send_mail(role, ONBOARDING_KIBE_CHEF, SacCas::JUGEND_EMAIL)
  end

  def fabe_chef_onboarding(role)
    send_mail(role, ONBOARDING_FABE_CHEF, SacCas::JUGEND_EMAIL)
  end

  def jo_chef_onboarding(role)
    send_mail(role, ONBOARDING_JO_CHEF, SacCas::JUGEND_EMAIL)
  end

  def huettenchef_onboarding(role)
    send_mail(role, ONBOARDING_HUETTENCHEF, SacCas::HUETTEN_EMAIL)
  end

  def huettenwart_onboarding(role)
    send_mail(role, ONBOARDING_HUETTENWART, SacCas::HUETTEN_EMAIL)
  end

  private

  def send_mail(role, content_key, bcc)
    @role = role
    @person = role.person
    headers[:bcc] = [bcc].compact_blank

    I18n.with_locale(@person.language) do
      compose(@person.email, content_key)
    end
  end

  def placeholder_role_name
    @role.class.model_name.human
  end

  def placeholder_role_start
    return unless @role.start_on

    I18n.l(@role.start_on)
  end

  def placeholder_role_end
    return unless @role.end_on

    I18n.l(@role.end_on)
  end

  def placeholder_role_group
    @role.group
  end

  def placeholder_role_sektion
    @role.layer_group
  end
end
