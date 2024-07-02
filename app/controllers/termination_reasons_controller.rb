# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class TerminationReasonsController < SimpleCrudController
  self.permitted_attrs = [:text]

  def destroy
    destroyed = entry.destroy or set_failure_notice
    respond_with(entry, success: destroyed, location: index_path)
  rescue ActiveRecord::InvalidForeignKey
    flash[:alert] = t('.foreign_key_error')
    respond_with(entry, success: false, location: index_path)
  end

  private

  def model_scope
    model_class.includes(:translations)
  end
end
