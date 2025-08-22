# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People
  class AccountCompletionsController < ApplicationController
    skip_before_action :authenticate_person!
    skip_authorization_check

    helper_method :person

    rescue_from ActiveSupport::MessageVerifier::InvalidSignature do
      redirect_to :root, alert: t("global.token_invalid")
    end

    def update
      person.attributes = model_params
      person.unconfirmed_email ||= "invalid" # NOTE: blanks are normally allowed but not here
      if person.valid? && person.save && person.send_confirmation_instructions
        redirect_to new_person_session_path, notice: [
          t("devise.confirmations.send_instructions"),
          t(".explain_confirmation_email")
        ]
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def person
      @person ||= Person.find_by_token_for!(:account_completion, params[:token])
    end

    def model_params
      params.key?(:person) ? params.require(:person).permit(:unconfirmed_email, :password, :password_confirmation) : {}
    end
  end
end
