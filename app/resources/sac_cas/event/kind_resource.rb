# frozen_string_literal: true
#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

module SacCas::Event::KindResource
  extend ActiveSupport::Concern

  included do
    with_options writable: false do
      attribute :maximum_participants, :integer
      attribute :minimum_participants, :integer
      attribute :training_days, :integer
      attribute :season, :string
      attribute :accommodation, :string
    end

    belongs_to :level, resource: Event::LevelResource
  end
end
