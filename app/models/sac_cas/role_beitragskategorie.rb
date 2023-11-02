# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module ::SacCas::RoleBeitragskategorie
  extend ActiveSupport::Concern

  included do
    include I18nEnums
    i18n_enum :beitragskategorie,
              ::SacCas::Beitragskategorie::Calculator::BEITRAGSKATEGORIEN,
              i18n_prefix: 'roles.beitragskategorie'

    attr_readonly :beitragskategorie

    before_validation :set_beitragskategorie, unless: :beitragskategorie

    validates :beitragskategorie, presence: true
  end

  def to_s(format = :default)
    "#{super} (#{beitragskategorie_label})"
  end

  private

  def set_beitragskategorie
    category =
      ::SacCas::Beitragskategorie::Calculator
      .new(person).calculate
    self.beitragskategorie = category
  end
end
