# frozen_string_literal: true
#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistration
  include ActiveModel::Model
  extend ActiveModel::Naming

  attr_accessor :group, :main_person_attributes, :housemates_attributes, :step, :single

  class_attribute :partials, default: [:main_person, :household, :summary]

  def initialize(group:, params:)
    @group = group
    @step = params[:step].to_i
    @main_person_attributes = extract_attrs(params, :main_person_attributes).to_h
    @housemates_attributes = extract_attrs(params, :housemates_attributes, array: true).to_a
  end

  def save!
    Person.transaction do
      people_models = create_people
      create_roles(people_models)
    end
  end

  def valid?
    people_valid?
  end

  def people
    @people ||= ([main_person] + housemates)
  end

  def housemates
    @housemates ||= build_housemates
  end

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end

  def main_person_email
    main_person.email
  end

  def increment_step
    @step += 1
  end

  def last_step?
    @step == (partials.size - 1)
  end

  def first_step?
    @step.zero?
  end

  private

  def people_valid?
    people.map(&:valid?).all?
  end

  def build_person(attrs, model_class)
    attrs = attrs.merge(
      primary_group_id: @group.id,
      household_key: household_key,
      household_emails: household_emails
    )
    model_class.new(attrs)
  end

  def build_housemates
    @housemates_attributes.map do |attrs|
      next if attrs[:_destroy] == '1'

      build_person(attrs, Housemate)
    end.compact
  end

  def create_people
    people.map(&:person).tap do |people|
      people.each(&:save!)
    end
  end

  def create_roles(people)
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
    (housemates_attributes + [main_person_attributes]).pluck(:email)
  end

  def extract_attrs(nested_params, key, array: false)
    params = nested_params.dig(self.class.model_name.param_key.to_sym, key).to_h
    array ? params.values : params
  end

end
