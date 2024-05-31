  module People
  class MembershipChangesController < ApplicationController
    # TODO: only allow if self_registration_active? (maybe in ability?)
    before_action :authorize
    before_action :group
    helper_method :entry, :person, :group, :policy_finder

    def new; end

    def create
      return render :new if params[:autosubmit].present?
      return save_and_redirect if entry.valid? && entry.last_step?

      entry.move_on
      render :new
    end

    private

    def save_and_redirect
      save_entry
      redirect_to new_person_session_path, notice: success_message
    end

    def save_entry
      Person.transaction do
        entry.save!
        enqueue_notification_email
      end
    end

    def entry
      @entry ||= model_class.new(
        current_ability:,
        params: model_params.to_unsafe_h,
        current_step: params[:step]
      )
    end

    def model_params
      params[model_identifier] || ActionController::Parameters.new
    end

    def model_identifier
      @model_identifier ||= model_class.model_name.param_key
    end

    def model_class
      @model_class ||= Wizards::MembershipChange
    end

    def group
      @group = Group.find(params[:group_id])
    end

    def person
      @person ||= Person.find(params[:person_id])
    end

    def new_person?
      params[:person_id].blank?
    end

    def enqueue_notification_email
      return if group.self_registration_notification_email.blank?

      ::Groups::SelfRegistrationNotificationMailer
        .self_registration_notification(group.self_registration_notification_email,
                                        entry.main_person.role).deliver_later
    end

    def success_message
      # TODO: user can also be confirmed already
      key = entry.person.email.present? ? :signed_up_but_unconfirmed : :signed_up_but_no_email
      I18n.t("devise.registrations.#{key}")
    end

    def policy_finder
      @policy_finder ||= Group::PrivacyPolicyFinder.for(group: group, person: entry.main_person)
    end

    def authorize
      authorize!(:edit, person)
    end


  end
end
