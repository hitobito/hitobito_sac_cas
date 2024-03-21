# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::Sektion::Housemate < SelfRegistration::MainPerson::Base
  MAX_ADULT_COUNT = SacCas::Role::MitgliedFamilyValidations::MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT

  self.active_model_only_attrs += [:household_emails, :supplements, :adult_count, :_destroy]

  self.required_attrs = [
    :first_name, :last_name, :birthday
  ]

  self.attrs = required_attrs + active_model_only_attrs +  [
    :gender, :email, :primary_group, :household_key
  ]

  validate :assert_adult_count
  validate :assert_family_age

  delegate :register_on_date, :newsletter, to: :supplements, allow_nil: true

  def person
    super.tap do |p|
      p.privacy_policy_accepted_at = Time.zone.now if supplements&.sektion_statuten
    end
  end

  public :role

  private

  def assert_adult_count
    if adult_count.to_i >= MAX_ADULT_COUNT && person.adult?
      errors.add(:base, too_many_adults_message)
    end
  end

  def assert_family_age
    calculator = SacCas::Beitragskategorie::Calculator.new(person)
    return if calculator.family_age? # everyting in order, no need to check further

    errors.add(:birthday, :too_young_for_family) if calculator.pre_school_child?
    errors.add(:birthday, :youth_not_allowed_in_family) if calculator.youth?
  end

  def too_many_adults_message
    I18n.t('activerecord.errors.messages.too_many_adults_in_family', max_adults: MAX_ADULT_COUNT)
  end
end
