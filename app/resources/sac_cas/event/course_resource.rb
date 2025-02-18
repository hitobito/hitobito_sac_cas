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
      attribute :meals, :string
      attribute :season, :string
      attribute :start_point_of_time, :string
      attribute :minimum_age, :integer
    end

    with_options writable: false, filterable: false do
      attribute :brief_description, :string
      attribute :specialities, :string
      attribute :similar_tours, :string
      attribute :program, :string
      attribute :link_external_site, :string

      attribute :price_member, :float
      attribute :price_regular, :float
      attribute :price_subsidized, :float
      attribute :price_special, :float
    end
  end
end
