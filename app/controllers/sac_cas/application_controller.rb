# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::ApplicationController
  extend ActiveSupport::Concern

  prepended do
    layout "with_google_tag_manager"
  end

  private

  def fetch_person
    return super unless current_person.backoffice?

    group
    Person.find(params[:id])
  end
end
