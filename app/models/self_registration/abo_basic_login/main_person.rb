# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::AboBasicLogin::MainPerson < SelfRegistration::MainPerson::Base
  AGREEMENTS = [
    :statutes,
    :data_protection,
  ].freeze

  AGREEMENTS.each do |agreement|
    attribute agreement, :boolean, default: false
    validates agreement, acceptance: true
  end

  attribute :newsletter, :boolean

  self.attrs = [
    :first_name, :last_name, :email, :gender, :birthday,
    :address_care_of, :street, :housenumber, :postbox, :zip_code, :town, :country,
    :number, :primary_group
  ]

  self.required_attrs = [
    :first_name, :last_name, :email, :birthday
  ]

  self.active_model_only_attrs += [:newsletter] + AGREEMENTS

  def self.human_attribute_name(key, options = {})
    links = Regexp.new((AGREEMENTS).join('|'))
    case key
    when links then I18n.t("link_#{key}_title", scope: 'self_registration.infos_component')
    else super(key, options)
    end
  end

  def link_translations(key)
    ["link_#{key}_title", "link_#{key}"].map do |str|
      I18n.t(str, scope: 'self_registration.infos_component')
    end
  end
end
