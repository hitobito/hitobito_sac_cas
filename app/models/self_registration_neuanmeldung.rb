# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung < SelfRegistration
  attr_accessor :housemates_attributes, :supplements_attributes

  self.partials = [:main_email, :neuanmeldung_main_person, :household, :supplements]

  def self.model_name
    ActiveModel::Name.new(SelfRegistration, nil)
  end

  def initialize(group:, params:)
    super
    @housemates_attributes = extract_attrs(params, :housemates_attributes, array: true).to_a
    @supplements_attributes = extract_attrs(params, :supplements_attributes)
  end

  def save!
    super.then do
      housemates.all?(&:save!)
    end
  end

  def housemates
    @housemates ||= build_housemates
  end

  def supplements
    @supplements ||= Supplements.new(@supplements_attributes)
  end

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end

  def birthdays
    housemates.collect(&:birthday).unshift(main_person.birthday).compact.shuffle
  end

  private

  def household_valid?
    housemates.all?(&:valid?)
  end

  def main_email_valid?
    main_person.email.present?
  end

  def supplements_valid?
    supplements.valid?
  end

  def build_person(*args)
    super(*args) do |attrs|
      attrs.merge(
        household_key: household_key,
        household_emails: household_emails,
        supplements: supplements
      )
    end
  end

  def build_housemates
    @housemates_attributes.map do |attrs|
      next if attrs[:_destroy] == '1'

      build_person(attrs, Housemate)
    end.compact
  end

  def household_key
    if @housemates_attributes.present?
      @household_key ||= loop do
        key = SecureRandom.uuid
        break key if ::Person.where(household_key: key).none?
      end
    end
  end

  def household_emails
    (housemates_attributes + [main_person_attributes]).pluck(:email).compact
  end
  alias neuanmeldung_main_person_valid? main_person_valid?
end
