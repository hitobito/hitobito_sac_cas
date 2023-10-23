# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Role

  private

  def set_first_primary_group
    update_primary_group!
  end

  def reset_primary_group
    update_primary_group!
  end

  def update_primary_group!
    person.update!(primary_group: Groups::Primary.new(person).identify)
  end
end
