# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People
  class AccountCompletionsController < ApplicationController
    skip_before_action :authenticate_person!
    skip_authorization_check

    helper_method :account_completion

    delegate :person, to: :account_completion
    delegate :send_confirmation_instructions, to: :person

    def show
      flash.now[:alert] = t(".token_expired") if account_completion.expired?
      account_completion.attributes = model_params
    end

    def update
      account_completion.attributes = model_params

      if account_completion.valid? && update_person && person.send_confirmation_instructions
        redirect_to person_path(account_completion.person), notice: t("devise.confirmations.send_instructions")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def update_person
      person.update(
        unconfirmed_email: account_completion.email,
        password: account_completion.password,
        password_confirmation: account_completion.password_confirmation
      )
    end

    def account_completion
      @account_completion ||= AccountCompletion
        .joins(:person)
        .where(people: {email: nil})
        .find_by!(token: params[:token])
    end

    def model_params
      params.key?(:account_completion) ? params.require(:account_completion).permit(:email, :email_confirmation, :password, :password_confirmation) : {}
    end
  end
end
