#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards
  module Steps
    module SwitchStammsektion
      class ChooseSektion < Wizards::Steps::ChooseSektion
        delegate :person, to: :wizard
        delegate :sac_membership_family?, :household, to: :person

        def family_names
          household.people.map(&:to_s).to_sentence
        end
      end
    end
  end
end
