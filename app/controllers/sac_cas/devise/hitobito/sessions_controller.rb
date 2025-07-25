# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Devise::Hitobito::SessionsController
  extend ActiveSupport::Concern

  prepended do
    prepend_before_action :redirect_if_unconfirmed, only: :create # rubocop:disable Rails/LexicallyScopedActionFilter
  end

  private

  def redirect_if_unconfirmed
    person = Person.where_login_matches(params.dig(:person, :login_identity))
      .find_by(confirmed_at: nil)

    if person&.valid_password?(params.dig(:person, :password))
      person.send_confirmation_instructions
      redirect_to new_session_path(:person), alert: t("devise.sessions.create.confirm_email_before_logging_in")
    end
  end

  def after_sign_in_path_for(resource)
    return super if current_user.root? || current_user.roles.any?

    group_self_registration_path(group_id: Group::AboBasicLogin.first.id, completion_redirect_path: super)
  end
end
