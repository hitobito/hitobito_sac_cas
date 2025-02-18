# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Signup::AboMagazinMailer < ApplicationMailer
  include MultilingualMailer
  include CommonMailerPlaceholders
  include ActionView::Helpers::NumberHelper

  CONFIRMATION = "abo_magazin_signup"

  def confirmation(person, group, newsletter_subscribed)
    @person = person
    @group = group
    @newsletter_subscribed = newsletter_subscribed
    locales = [person.language]

    compose_multilingual(person, CONFIRMATION, locales)
  end

  private

  def placeholder_costs
    cost = Group.root.abo_alpen_fee
    cost += Group.root.abo_alpen_postage_abroad if @person.living_abroad?
    formatted_value = number_with_precision(cost,
      precision: I18n.t("number.currency.format.precision"),
      delimiter: I18n.t("number.currency.format.delimiter"))

    [I18n.t("global.currency"), formatted_value].join(" ")
  end

  def placeholder_gender
    @person.gender_label
  end

  def placeholder_abo_name
    @group.name
  end

  def placeholder_agb_link
    infos_component_link(:agb)
  end

  def placeholder_data_protection_link
    infos_component_link(:data_protection)
  end

  def placeholder_language
    Person::LANGUAGES[@person.language.to_sym]
  end

  def placeholder_newsletter_subscribed
    return unless @newsletter_subscribed

    I18n.t("wizards.steps.signup.agreement_fields.newsletter_caption", locale: @person.language)
  end

  def infos_component_link(key)
    scope = "self_registration.infos_component"
    link_to(t("link_#{key}_title", scope: scope), t("link_#{key}", scope: scope))
  end
end
