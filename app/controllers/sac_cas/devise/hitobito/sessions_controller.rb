# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Devise::Hitobito::SessionsController
  extend ActiveSupport::Concern

  def create
    super.tap do |resource|
      if resource.data_quality_issues.present?
        flash[:notice] = I18n.t("devise.sessions.data_quality_alert")
      end
    end
  end
end
