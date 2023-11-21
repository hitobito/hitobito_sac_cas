# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Sheet::Person

  def self.included(target)
    target.tab 'people.tabs.memberships',
               :memberships_group_person_path,
               if: (lambda do |view, _group, person|
                 # We want to show the memberships tab only, if the history tab is not visible
                 # as they are the same just with different labels/paths.
                 # Show the tab if person can :memberships, but only if she cannot :history.
                 view.can?(:memberships, person) && view.cannot?(:history, person)
               end)
  end

end
