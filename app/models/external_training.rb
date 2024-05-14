# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalTraining < ActiveRecord::Base
  validates_by_schema

  belongs_to :person
  belongs_to :event_kind, class_name: 'Event::Kind'

  attr_accessor :other_people_ids

  validates_date :finish_at, on_or_after: :start_at, allow_blank: true

  scope :list, -> { order(created_at: :desc) }

  after_destroy :revoke_qualifications
  after_save :issue_qualifications
  after_save :create_trainings_for_other_people

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

  alias kind event_kind

  private

  def qualifier
    ExternalTrainings::Qualifier.new(person, self, 'participant')
  end

  def issue_qualifications
    qualifier.issue
  end

  def revoke_qualifications
    qualifier.revoke
  end

  def create_trainings_for_other_people
    Array(other_people_ids).each do |person_id|
      ExternalTraining.create!(attributes.except('id', 'person_id').merge(person_id: person_id))
    end
  end

end
