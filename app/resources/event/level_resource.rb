# frozen_string_literal: true

#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class Event::LevelResource < ApplicationResource
  self.type = "event_levels"

  with_options writable: false do
    attribute :label, :string
    attribute :code, :integer
    attribute :difficulty, :integer
    attribute :description, :string
  end

  def base_scope
    Event::Level.where(deleted_at: nil).list
  end
end
