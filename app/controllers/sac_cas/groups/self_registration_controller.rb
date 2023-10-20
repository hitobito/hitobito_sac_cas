# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SacCas::Groups::SelfRegistrationController < ApplicationController
  skip_authorization_check

  before_action :assert_empty_honeypot, only: [:create]
  before_action :redirect_to_group_if_necessary
  helper_method :entry, :policy_finder

  def new
  end

  def create
    return render :new unless entry.valid?

    if params.key?(:step)
      entry.increment_step
      render :new, entry: entry
    else
      save_entry
      redirect_to new_person_session_path, notice: success_message
    end
  end

  private

  def save_entry
    Person.transaction do
      entry.save!
      enqueue_notification_email
      send_password_reset_email
    end
  end

  def entry
    @entry ||= ::Groups::SelfRegistration.new(
      group: group,
      params: params.to_unsafe_h.deep_symbolize_keys
    )
  end

  def authenticate?
    false
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def assert_empty_honeypot
    if params.delete(:verification).present?
      redirect_to new_person_session_path
    end
  end

  def redirect_to_group_if_necessary
    return redirect_to group_path(group) unless group.self_registration_active?

    redirect_to group_self_inscription_path(group) if signed_in?
  end

  def enqueue_notification_email
    return if group.self_registration_notification_email.blank?

    ::Groups::SelfRegistrationNotificationMailer
      .self_registration_notification(group.self_registration_notification_email,
                                      entry).deliver_later
  end

  def send_password_reset_email
    return unless entry.person_email.present?

    Person.send_reset_password_instructions(email: entry.person_email)
  end

  def success_message
    key = entry.person.email.present? ? :signed_up_but_unconfirmed : :signed_up_but_no_email
    I18n.t("devise.registrations.#{key}")
  end

  def policy_finder
    @policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: entry.person)
  end

end
