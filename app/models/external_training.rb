# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalTraining < ActiveRecord::Base
  validates_by_schema

  belongs_to :person
  belongs_to :event_kind, class_name: 'Event::Kind'

  validates_date :finish_at, after: :start_at

  scope :list, -> { order(created_at: :desc) }

  def self.between(start_date, end_date)
    where('start_at <= :end_date AND finish_at >= :start_date ',
          start_date: start_date, end_date: end_date).distinct
  end

  def to_s
    name
  end

  def start_date
    start_at
  end

  def qualification_date
    finish_at
  end

  alias_method :kind, :event_kind
end
