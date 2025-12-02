# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Memberships::TerminateAboMagazinAbonnent
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :terminate_on, :date
  attribute :subscribe_newsletter, :boolean, default: false
  attribute :subscribe_fundraising_list, :boolean, default: false
  attribute :data_retention_consent, :boolean, default: false
  attribute :entry_fee_consent, :boolean, default: false
  attribute :online_articles_consent, :boolean, default: false

  validates :entry_fee_consent, acceptance: true
  validates :online_articles_consent, acceptance: true
  validates :terminate_on, inclusion: {in: :terminate_on_values}

  delegate :person, to: :role
  delegate :human_attribute_name, to: :class

  attr_reader :role

  def initialize(role, attributes = {})
    @role = role
    super(attributes)
  end

  def save
    return false unless valid?

    Role.transaction do
      terminate_role
      cancel_invoices
      handle_basic_login
      newsletter&.subscribe_if(person, subscribe_newsletter)
      fundraising&.subscribe_if(person, subscribe_fundraising_list)
      person.update!(data_retention_consent: data_retention_consent)
    end
  end

  def terminate_on_options
    [
      [human_attribute_name(:now), Date.yesterday],
      [human_attribute_name(:end_of_role, date: I18n.l(role.end_on)), role.end_on]
    ]
  end

  def submit_enabled?
    [entry_fee_consent, online_articles_consent].all?
  end

  private

  def terminate_role
    Roles::Termination.new(role:, terminate_on:, validate_terminate_on: false).call
  end

  def handle_basic_login
    basic_login_role = person.roles.find_by(basic_login_conditions)

    if data_retention_consent
      create_basic_login unless basic_login_role
    elsif basic_login_role && (person.roles - [role, basic_login_role]).empty?
      basic_login_role.update!(end_on: terminate_on)
    end
  end

  def create_basic_login
    person.roles.create!(basic_login_conditions.merge(start_on: terminate_on + 1.day))
  end

  def cancel_invoices
    cancelable_invoices.each do |invoice|
      invoice.update!(state: :cancelled)
      Invoices::Abacus::CancelInvoiceJob.new(invoice).enqueue!
    end
  end

  def cancelable_invoices
    ExternalInvoice::AboMagazin
      .where(person_id: person.id)
      .where(link: role.group)
      .where(year: Time.zone.now.next_year.year)
      .select(&:cancellable?)
  end

  def basic_login_conditions
    @basic_login_conditions ||= {
      group: Group::AboBasicLogin.find_by(layer_group_id: Group.root_id),
      type: Group::AboBasicLogin::BasicLogin.sti_name
    }
  end

  def newsletter
    @newsletter ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
  end

  def fundraising
    @fundraising ||= MailingList.find_by(id: Group.root.sac_fundraising_mailing_list_id)
  end

  def terminate_on_values = terminate_on_options.map(&:second)
end
