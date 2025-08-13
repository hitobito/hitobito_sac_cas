# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Devise::Hitobito::ConfirmationsController
  extend ActiveSupport::Concern

  private

  def show
    super do |resource|
      next unless resource.valid?
      AccountCompletion.where(person: resource).delete_all
    end
  end
end
