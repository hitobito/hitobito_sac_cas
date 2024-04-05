# frozen_string_literal: true
#
# Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

module SacCas::Event::CourseResource
  extend ActiveSupport::Concern

  included do
    with_options writable: false do
      attribute :language, :string
      attribute :accommodation, :string
      attribute :season, :string
      attribute :start_point_of_time, :string
      attribute :minimum_age, :integer
    end
  end
end
