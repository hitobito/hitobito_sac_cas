# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module FutureRole::FormHandling
  extend ActiveSupport::Concern

  MAX_REGISTER_ON_KEYS = 2

  def register_on_keys
    %w(now jul oct).reject do |key|
      date_from_key(key)&.past? || date_from_key(key)&.today?
    end.take(MAX_REGISTER_ON_KEYS)
  end

  def register_on_options
    build_options(:register_on, register_on_keys)
  end

  def register_on_date
    date_from_key(register_on) if register_on_keys.include?(register_on)
  end

  private

  def build_options(attr, list)
    list.collect { |key| [key, t("#{attr}_options", key)] }
  end

  def date_from_key(key)
    index = Date::ABBR_MONTHNAMES.index(key.to_s.capitalize)
    Date.new(today.year, index) if index
  end

  def today
    @today ||= Time.zone.today
  end

  def t(*keys)
    I18n.t(keys.join('.'), scope: 'activemodel.attributes.self_inscription')
  end
end
