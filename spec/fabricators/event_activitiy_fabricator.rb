# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:event_activity, class_name: "Event::Activity") do
  label { Faker::Sport.sport }
  description { Faker::Lorem.sentence }
  after_build do |activity|
    if activity.parent_id
      activity.technical_requirement = Fabricate(:event_technical_requirement)
    end
  end
end
