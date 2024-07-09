# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module CapitalizedDependentErrors
  extend ActiveSupport::Concern

  def errors
    super.tap { |errors| capitalize_dependent_records(errors) }
  end

  private

  # NOTE ama - https://github.com/rails/rails/issues/21064
  def capitalize_dependent_records(errors)
    errors.each do |error|
      if error.type == :"restrict_dependent_destroy.has_many"
        error.options[:record].capitalize!
      end
    end
  end
end
