# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module ::SacCas::RoleBeitragskategorie
  extend ActiveSupport::Concern
  include I18nEnums

  included do
    i18n_enum :beitragskategorie,
              ::SacCas::Beitragskategorie::Calculator::BEITRAGSKATEGORIEN,
              i18n_prefix: 'roles.beitragskategorie'

    attr_readonly :beitragskategorie

    before_validation :set_beitragskategorie

    before_save :ensure_beitragskategorie, if: :validate_beitragskategorie?

    ::SacCas::Beitragskategorie::Calculator::BEITRAGSKATEGORIEN.each do |category|
      scope category, -> { where(beitragskategorie: category) }
    end
  end

  def beitragskategorie
    value = read_attribute(:beitragskategorie)
    value.inquiry if value
  end

  def to_s(format = :default)
    if beitragskategorie_label
      "#{super(:short)} (#{beitragskategorie_label})"
    else
      super
    end
  end

  def set_beitragskategorie
    return if beitragskategorie?

    self.beitragskategorie = ::SacCas::Beitragskategorie::Calculator.new(person).calculate
  end

  private

  # This method is called by the `before_validation` callback. It is used to
  # determine whether the beitragskategorie should be validated or not.
  # It is overwritten in the FutureRole to make the validation conditional
  # on the target_type.
  def validate_beitragskategorie?
    true
  end

  def ensure_beitragskategorie
    # This is a safeguard to ensure that the beitragskategorie is set before
    # the record is saved. We assume this should never happen, as the beitragskategorie
    # gets set in the `before_validation` callback. If it is not set, then the
    # person.birthdate should have a validation error which makes the role record invalid.
    raise "beitragskategorie not set" unless beitragskategorie?
  end
end
