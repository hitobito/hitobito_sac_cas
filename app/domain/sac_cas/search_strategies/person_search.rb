#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::SearchStrategies
  module PersonSearch
    def search_fulltext
      return no_people unless term_present?

      if ability.can?(:read_all_people, @user)
        return Person.search(@term)
      end

      super
    end

    private

    def no_people
      Person.none.page(1)
    end

    def ability
      Ability.new(@user)
    end
  end
end
