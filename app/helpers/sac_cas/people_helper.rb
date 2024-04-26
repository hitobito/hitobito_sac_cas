# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleHelper
  def format_person_digital_correspondence(entry)
    key = entry.digital_correspondence ? :digital : :print
    t(:"people.fields_sac_cas.digital_correspondence.#{key}")

  def format_person_family_main_person(person)
    main_person = person.sac_family.main_person

    if person == main_person
      f(true)
    elsif main_person.nil?
      ti('.unknown')
    else
      link_to(main_person.to_s, main_person)
    end
  end
end
