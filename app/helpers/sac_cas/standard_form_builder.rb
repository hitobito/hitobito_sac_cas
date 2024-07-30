# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::StandardFormBuilder
  def labeled_gender_inline_radio_buttons
    radios = (Person::GENDERS + [""]).map do |key|
      inline_radio_button(:gender, key, Person.salutation_label(key))
    end
    labeled(:gender, safe_join(radios))
  end
end
