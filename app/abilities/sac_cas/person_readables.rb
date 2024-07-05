# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club.
#  This file is part of hitobito_youth and
#  licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

module SacCas::PersonReadables
  def accessible_people
    return Person.only_public_data if can?(:read_all_people, user)

    super
  end
end
