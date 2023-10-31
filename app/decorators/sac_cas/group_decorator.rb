# frozen_string_literal: true
c
#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::GroupDecorator

  def primary_group_toggle_link(person)
    group = object
    if model.preferred_primary?
      super(person, group, title: I18n.t('people.roles.roles_aside.set_hauptsektion'))
    elsif !person.primary_group.preferred_primary?
      super(person, group)
    end
  end
end
