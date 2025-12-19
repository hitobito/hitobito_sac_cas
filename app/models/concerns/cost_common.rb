# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module CostCommon
  extend ActiveSupport::Concern

  include Paranoia::Globalized

  included do
    include CapitalizedDependentErrors

    translates :label

    validates :label, presence: true
    validates :code, uniqueness: true

    scope :list, -> { includes(:translations).order(:code) }

    has_many :event_kind_categories, class_name: "Event::KindCategory",
      dependent: :restrict_with_error

    has_many :event_kinds, class_name: "Event::Kind",
      dependent: :restrict_with_error

    validates_by_schema
  end

  def to_s
    [code, label].join(" - ")
  end

  def destroy
    if dependent_associations_exist?
      delete
    else
      really_destroy!
    end
  end

  private

  def dependent_associations_exist?
    [event_kind_categories, event_kinds].any?(&:exists?)
  end
end
