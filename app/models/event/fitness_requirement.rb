# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: event_fitness_requirement
#
#  id                :bigint           not null, primary key
#  order             :integer          not null, default 0
#  short_label       :string(5)
#  label             :string(255)
#  short_description :string(255)
#  description       :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#

class Event::FitnessRequirement < ActiveRecord::Base
  include Paranoia::Globalized

  translates :short_label, :label, :description, :short_description

  has_many :events, dependent: :nullify

  validates_by_schema
  validates :short_label, :label, :description, presence: true
  validates :short_label, :label, uniqueness: true
  # validates_by_schema does not work on translated attributes
  validates :short_label, length: {maximum: 5}

  scope :list, -> { includes(:translations).order(:order) }
  scope :assignable, ->(ids = []) { without_deleted.or(where(id: ids)) }

  def to_s(_format = :default)
    label
  end

  # Soft destroy if events exist, otherwise hard destroy
  def destroy
    if events.exists?
      delete
    else
      really_destroy!
    end
  end
end
