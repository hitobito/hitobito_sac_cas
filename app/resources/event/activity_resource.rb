# frozen_string_literal: true

# Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito_sac_cas.

class Event::ActivityResource < ApplicationResource
  primary_endpoint "event_activities", %i[index show]

  self.type = "event_activities"

  with_options writable: false do
    attribute :label, :string
    attribute :short_description, :string
    attribute :description, :string
    attribute :order, :integer
    attribute :color, :string

    extra_attribute :icon, :string do
      next unless @object.icon.attached?

      context.rails_storage_proxy_url(@object.icon.blob)
    end
  end

  has_one :parent, resource: self

  def base_scope
    Event::Activity.without_deleted
  end
end
