# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::MainPerson::Base < SelfRegistration::Person
  delegate :salutation_label, :phone_numbers, :address, to: :person
  validate :assert_valid_phone_number

  class_attribute :active_model_only_attrs
  self.active_model_only_attrs = [:number]

  attr_accessor :register_on_date

  def initialize(*args)
    super
    self.country ||= Settings.addresses.imported_countries.to_a.first if respond_to?(:country)
  end

  def person
    @person ||= Person.new(active_record_attrs).tap do |p|
      assign_number(p)
    end
  end

  def save!
    super(context: 'selfreg')
    exclude_from_mailing_list if mailing_list && !newsletter
  end

  def valid?
    super('selfreg') && person.valid?('selfreg')
  end

  private

  def active_record_attrs
    attributes.compact.except(*active_model_only_attrs.collect(&:to_s))
  end

  def assign_number(person)
    return if attributes['number'].blank?

    person.phone_numbers.build(label: 'Mobil', number: attributes['number'])
  end

  def assert_valid_phone_number
    errors.add(:number, :invalid) if phone_numbers.any? && phone_numbers.none?(&:valid?)
  end

  def exclude_from_mailing_list
    mailing_list.subscriptions.create!(subscriber: person, excluded: true)
  end

  def mailing_list
    @mailing_list ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
  end

  def role
    @role ||= (future_role? ? build_future_role : build_role)
  end

  def build_future_role
    FutureRole.new(
      person: person,
      group: primary_group,
      convert_on: register_on_date,
      convert_to: role_type
    )
  end

  def build_role
    Role.new(
      person: person,
      group: primary_group,
      type: role_type,
      created_at: Time.zone.now,
      delete_on: (Time.zone.today.end_of_year unless neuanmeldung?)
    )
  end

  def future_role?
    respond_to?(:register_on_date) && register_on_date&.future?
  end

  def neuanmeldung?
    primary_group.is_a?(Group::SektionsNeuanmeldungenSektion) ||
    primary_group.is_a?(Group::SektionsNeuanmeldungenNv)
  end
end
