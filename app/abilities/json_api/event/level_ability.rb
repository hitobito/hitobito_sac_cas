# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class JsonApi::Event::LevelAbility
  include CanCan::Ability

  def initialize(main_ability)
    can :read, Event::Level if main_ability.can?(:list_available, Event)
  end
end
