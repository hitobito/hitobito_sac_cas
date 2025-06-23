# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::JsonApi::PeopleController
  extend ActiveSupport::Concern

  private

  def entry
    @entry ||= resource_class.new.base_scope.find(params[:id])
  end
end
