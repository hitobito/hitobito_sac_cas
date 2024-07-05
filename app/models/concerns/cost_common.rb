# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module CostCommon
  extend ActiveSupport::Concern
  included do
    include Globalized
    translates :label

    validates :label, presence: true
    validates :code, uniqueness: true

    default_scope { where(deleted_at: nil) }

    scope :list, -> { includes(:translations).order(:code) }
    scope :with_deleted, -> { unscope(where: :deleted_at) }

    has_many :event_kind_categories, class_name: "Event::KindCategory",
      dependent: :restrict_with_error

    has_many :event_kinds, class_name: "Event::Kind",
      dependent: :restrict_with_error

    validates_by_schema
  end

  def to_s
    [code, label].join(" - ")
  end

  def errors
    super.tap { |errors| capitalize_dependent_records(errors) }
  end

  def destroy
    return super if dependent_assocations_exist?

    soft_destroy
  end

  private

  def dependent_assocations_exist?
    [event_kind_categories, event_kinds].any?(&:exists?)
  end

  def soft_destroy
    update(deleted_at: Time.zone.now)
  end

  # NOTE ama - https://github.com/rails/rails/issues/21064
  def capitalize_dependent_records(errors)
    errors.each do |error|
      if error.type == :"restrict_dependent_destroy.has_many"
        error.options[:record].capitalize!
      end
    end
  end
end
