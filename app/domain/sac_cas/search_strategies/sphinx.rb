# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::SearchStrategies
  module Sphinx
    def query_people
      return Person.none.page(1) if @term.blank?

      if ability.can?(:read_all_people, @user)
        return Person.search(Riddle::Query.escape(@term), default_search_options)
      end

      super
    end

    protected

    def ability
      Ability.new(@user)
    end
  end
end
