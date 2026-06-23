#  Copyright (c) 2012-2024, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::SearchStrategies
  module PersonSearch
    extend ActiveSupport::Concern

    private

    def accessible_scope
      if ability.can?(:read_all_people, @user)
        # skip all other restrictions if user can read all people to optimize performance
        Person.all
      else
        super
      end
    end
  end
end
