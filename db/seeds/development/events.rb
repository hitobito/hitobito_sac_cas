# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('db', 'seeds', 'support', 'event_seeder')

srand(42)

#seeder = EventSeeder.new

#layer_types = Group.all_types.select(&:layer).collect(&:sti_name)
#Group.where(type: layer_types).pluck(:id).each do |group_id|
  #5.times do
    #seeder.seed_event(group_id, :base)
  #end
#end
