#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::SearchStrategies
  module Sql
    def query_people
      return Person.none.page(1) unless term_present?

      if ability.can?(:read_all_people, @user)
        return query_entities(Person.all).page(1).per(SearchStrategies::Sql::QUERY_PER_PAGE)
      end

      super
    end

    protected

    def ability
      Ability.new(@user)
    end
  end
end
