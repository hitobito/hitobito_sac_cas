# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# termination_reason is an optional belongs_to on an STI model.
# Some role types do not have a termination reason, so Bullet reports this as unused for those STI subclasses.
# To prevent N+1 queries we want to preload this for any role type and don't want a warning
# for every role type in the list without a record with termination reason
Rails.application.config.after_initialize do
  if defined? Bullet
    Role.all_types.map(&:to_s).each do
      Bullet.add_safelist(
        type: :unused_eager_loading,
        class_name: _1,
        association: :termination_reason
      )
    end
  end
end