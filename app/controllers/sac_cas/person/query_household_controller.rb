# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Person::QueryHouseholdController
  extend ActiveSupport::Concern

  prepended do
    self.search_columns = [:id, :birthday, :first_name, :last_name, :email]
  end

  def scope
    Person.only_public_data
  end

  def authorize_action
    authorize!(:create_households, Person)
  end

end
