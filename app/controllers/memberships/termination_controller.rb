# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class TerminationController < ApplicationController
    before_action :authorize, :person, :group # for sheet
    before_action :render_abort_views

    delegate :sac_membership, :household, to: :person
    helper_method :household, :sac_membership, :form_object

    helper_method :group, :person, :for_someone_else?,
      :mitglied_termination_by_section_only?, :choose_date?, :form_object

    def create
      form_object.attributes = model_params

      if form_object.valid?
        operation.save! && send_confirmation_mail
        redirect_to redirect_target, notice: success_message
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def form_object
      @form_object ||= self.class.name
        .gsub("sController", "Form")
        .classify.constantize.new(terminate_on_values)
    end

    def operation
      @operation ||= self.class.name
        .gsub("sController", "")
        .classify.constantize.new(role, **form_object.attributes_for_operation)
    end

    def model_params
      fail "implement in subclass"
    end

    def role
      fail "implement in subclass"
    end

    def authorize
      authorize!(:terminate, role)
    end

    def success_message
      t(".success", group_name: role.layer_group.name, count: operation.affected_people.count)
    end

    def terminate_on_values
      (for_someone_else? || !open_invoice?) ? %w[now end_of_year] : %w[now]
    end

    def send_confirmation_mail
      fail "implement in subclass"
    end

    def render_abort_views # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
      if sac_membership.stammsektion_role.terminated?
        render :terminated_already
      elsif sac_membership.family? && !(household.main_person == person)
        render :ask_family_main_person
      elsif !for_someone_else?
        if mitglied_termination_by_section_only?
          render :no_self_service
        elsif open_invoice? && Date.current.month > 1
          render :open_invoice_exists
        end
      end
    end

    def open_invoice?
      @open_invoice ||= person.external_invoices
        .where(type: ExternalInvoice::SacMembership.sti_name,
          year: Date.current.year)
        .open.exists?
    end

    def mitglied_termination_by_section_only?
      sektions = [role.layer_group] + household.people.flat_map { |person|
        person.sac_membership.zusatzsektion_roles.map(&:layer_group)
      }
      sektions.any?(&:mitglied_termination_by_section_only)
    end

    def for_someone_else?
      current_user != person
    end

    # if the current_user does not have the ability to show the person in other groups the person
    # has (or will have) roles in, we redirect to the member list and display the flash message
    # therefor format: :html is required otherwise it is redirect as turbo_stream
    def redirect_target
      if can?(:show, person)
        person_path(person, format: :html)
      else
        group_people_path(group, format: :html)
      end
    end

    def person
      @person ||= Person.find(params[:person_id])
    end

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
