#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class EventKindReadables
  include CanCan::Ability

  attr_reader :user_context

  delegate :user, to: :user_context

  def initialize(user)
    @user_context = AbilityDsl::UserContext.new(user)

    if user_has_permission_in_root_group? || user.root?
      can :index, Event::Kind
    else
      can :index, Event::Kind, section_may_create: true
    end
  end

  private

  def user_has_permission_in_root_group?
    permissions_to_check.any? do |permission|
      permitted_groups = user.groups_with_permission(permission)
      user_context.layer_ids(permitted_groups).include?(Group.root_id)
    end
  end

  def permissions_to_check = %i[layer_full layer_and_below_full group_full group_and_below_full]
end
