# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::GroupDecorator

  def primary_group_toggle_link(person, group)
    primary = Groups::Primary.new(person)
    return super(person, group) unless primary.identified?

    if model.preferred_primary? && primary.preferred?(model)
      if person.primary_group == model
        helpers.icon(:star, filled: true, title: I18n.t('people.roles.roles_aside.hauptsektion'))
      elsif can?(:primary_group, person)
        super(person, group, title: I18n.t('people.roles.roles_aside.set_hauptsektion'))
      end
    end
  end
end
