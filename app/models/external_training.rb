# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalTraining < ActiveRecord::Base
  validates_by_schema

  belongs_to :person
  belongs_to :event_kind, class_name: 'Event::Kind'

  scope :list, -> { order(created_at: :desc) }

  def to_s
    name
  end

end
