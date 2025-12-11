# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class TerminateAboMagazinAbonnentsController < TerminationController
    skip_before_action :render_abort_views

    helper_method :model, :i18n_scope

    def create
      model.attributes = model_params

      if model.save
        send_confirmation_mail

        redirect_to redirect_target, notice: t(".success")
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def send_confirmation_mail
      Memberships::TerminateAboMagazinAbonnentMailer.terminate_abonnent(
        person,
        model.terminate_on
      ).deliver_later
    end

    def model
      @model ||= Memberships::TerminateAboMagazinAbonnent.new(role)
    end

    def role
      @role ||= Role.find_by!(id: params[:role_id], type: Group::AboMagazin::Abonnent.sti_name)
    end

    def model_params
      params
        .require(:memberships_terminate_abo_magazin_abonnent)
        .permit(
          :terminate_on,
          :subscribe_newsletter,
          :subscribe_fundraising_list,
          :online_articles_consent,
          :data_retention_consent,
          :entry_fee_consent
        )
    end

    def i18n_scope = "wizards.steps.terminate_abo_magazin_abonnents"
  end
end
