# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfRegistration
  extend ActiveSupport::Concern

  attr_accessor :housemates_attributes

  prepended do
    self.partials = [:person, :household, :summary]
  end

  def initialize(group:, params:)
    super
    @housemates_attributes = extract_attrs(params, :housemates_attributes, array: true).to_a
  end

  def save!
    Person.transaction do
      super
      housemate_models = create_housemates
      create_housemate_roles(housemate_models)
    end
  end

  def valid?
    super && housemates_valid?
  end

  def housemates
    @housemates ||= build_housemates
  end

  private

  def housemates_valid?
    housemates.map(&:valid?).all?
  end

  def build_person(attrs, model_class = Person)
    attrs = attrs.merge(
      primary_group_id: @group.id,
      household_key: household_key,
      household_emails: household_emails
    )
    super(attrs, model_class)
  end

  def build_housemates
    @housemates_attributes.map do |attrs|
      next if attrs[:_destroy] == '1'

      build_person(attrs, Housemate)
    end.compact
  end

  def create_housemates
    housemates.map(&:person).tap do |people|
      people.each(&:save!)
    end
  end

  def create_housemate_roles(people)
    people.map do |person|
      Role.create!(
        group: @group,
        type: @group.self_registration_role_type,
        person: person
      )
    end
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
    housemates_attributes.pluck(:email)
  end

end
