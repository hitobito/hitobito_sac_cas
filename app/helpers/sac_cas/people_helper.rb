# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleHelper
  def format_person_sac_family_main_person(person)
    main_person = person.sac_family.main_person

    if person == main_person
      f(true)
    elsif main_person.nil?
      ti('.unknown')
    else
      if can?(:read, main_person)
        link_to(main_person.to_s, main_person)
      else
        main_person.to_s
      end
    end
  end
end
