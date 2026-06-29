# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ReportForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  EDITABLE_PARTICIPATION_STATES = %w[assigned attended absent].freeze

  attr_reader :report

  delegate :event, to: :report

  attribute :review, :string
  attribute :remarks, :string

  validate :assert_participation_states_editable

  def initialize(report, attrs = {})
    @report = report
    super({review: report.review, remarks: report.remarks, **attrs})
  end

  def save
    return false unless valid?

    report.update(review:, remarks:) && save_participations
  end

  def tour_completed?
    [:ready, :closed].include?(event.state.to_sym)
  end

  attr_writer :participations_attributes

  def participations
    @participations ||= event
      .participations
      .includes(:event, :roles)
      .where.not(state: ["rejected", "applied", "unconfirmed"])
      .order_by_role(event)
  end

  def editable_participation_state?(participation)
    EDITABLE_PARTICIPATION_STATES.include?(participation.state)
  end

  def participation_state_labels(participation)
    Event::Participation.state_labels(participation)
      .slice(*EDITABLE_PARTICIPATION_STATES
      .map(&:to_sym))
      .to_a
  end

  private

  def assert_participation_states_editable
    return unless @participations_attributes

    @participations_attributes.each do |id, attrs|
      next if attrs[:state].blank?

      unless editable_participation_state?(participation_by_id[id.to_i])
        errors.add(:base, :participation_state_not_editable)
      end
    end
  end

  def save_participations
    return true unless @participations_attributes

    @participations_attributes.all? do |id, attrs|
      participation = participation_by_id[id.to_i]
      participation.update(attrs)
    end
  end

  def participation_by_id
    @participation_by_id ||= participations.index_by(&:id)
  end
end
