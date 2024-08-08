# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class People::MembershipInvoicesController < ApplicationController
  before_action :validate_params, only: [:create]

  def create
    authorize!(:update, person)

    generate_invoice
    redirect_to external_invoices_group_person_path(group, person)
  end

  def new
    authorize!(:update, person)

    @group = group
    @date = date
    @person = person
    @context = context
    @member = member
  end

  private

  def generate_invoice
    handle_exceptions do
      ExternalInvoice::SacMembership.create!(
        state: :draft,
        year: Date.parse(params[:reference_date]).year,
        issued_at: params[:invoice_date],
        sent_at: params[:send_date],
        person: person,
        link: Group.find(params[:section_id])
      )
      set_flash(:success)
    end
  end

  def validate_params
    date_fields = %i[reference_date invoice_date send_date]
    date_field_names = [t(".new.reference_date"), t(".new.invoice_date"), t(".new.send_date")]

    # is person already a member for next year?
    delete_on_date = person.sac_membership.stammsektion_role.delete_on

    errors = date_fields.zip(date_field_names).map do |key, field_name|
      date = params[key]

      valid_date_range = if key == :send_date && delete_on_date.year > Time.zone.today.year
        Time.zone.today.year..Time.zone.today.year
      else
        Time.zone.today.year..Time.zone.today.year + 1
      end

      if date.blank?
        "#{field_name} #{t(".new.presence")}"
      elsif invalid_date?(date, valid_date_range)
        "#{field_name} #{t(".new.invalid_date")}"
      end
    end

    errors << t(".new.discount_invalid") unless [0, 50, 100].include?(params[:discount].to_i)

    if errors.compact.any?
      set_flash(:alert, message: errors.compact.join(", "))
      redirect_to new_group_person_membership_invoice_path(group, person)
    end
  end

  def set_flash(type, **args)
    kind = (type == :success) ? :notice : :alert
    flash[kind] = t("people.membership_invoices.#{type}_notice", **args) # rubocop:disable Rails/ActionControllerFlashBeforeRender
  end

  def handle_exceptions
    yield
  rescue => e
    set_flash(:alert, message: e.message)
    options = {}
    if e.respond_to?(:response)
      options[:extra] = {response: e.response.body.force_encoding("UTF-8")}
    end
    Raven.capture_exception(e, options)
  end

  def invalid_date?(date, valid_date_range)
    parsed_date = parse_date(date)
    parsed_date.nil? || !valid_date_range.cover?(parsed_date.year)
  end

  def parse_date(date)
    Date.parse(date)
  rescue ArgumentError, TypeError
    nil
  end

  def member
    @member ||= Invoices::SacMemberships::Member.new(person, context)
  end

  def person
    @person ||= context.people_with_membership_years.find(params[:person_id])
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def context
    @context ||= Invoices::SacMemberships::Context.new(date)
  end

  def date
    @date ||= params[:date].present? ? Date.parse(params[:date]) : Time.zone.today
  end
end
