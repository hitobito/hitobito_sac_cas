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
  attr_writer :participations_attributes

  delegate :event, to: :report

  attribute :review, :string
  attribute :remarks, :string

  validate :assert_participation_states_editable
  validate :assert_cost_records_valid

  def initialize(report, attrs = {})
    @report = report
    super({review: report.review, remarks: report.remarks, **attrs})
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      report.update!(review:, remarks:) && save_participations && save_cost_records
    end
  end

  def tour_completed?
    [:ready, :closed].include?(event.state.to_sym)
  end

  def participations
    @participations ||= event
      .participations
      .includes(:event, :roles)
      .where.not(state: ["rejected", "applied", "unconfirmed"])
      .order_by_role(event)
  end

  def revenues
    @revenues ||= report.costs.where(income: true).to_a
  end

  def expenditures
    @expenditures ||= report.costs.where(income: false).to_a
  end

  def receipts
    @receipts ||= report.cost_receipts.includes(:file_attachment).to_a
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

  def revenues_attributes=(attrs)
    @revenues = build_records(attrs, collection: report.costs, fixed_attributes: {income: true})
  end

  def expenditures_attributes=(attrs)
    @expenditures = build_records(attrs, collection: report.costs,
      fixed_attributes: {income: false})
  end

  def receipts_attributes=(attrs)
    @receipts = build_records(attrs, collection: report.cost_receipts)
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

  def assert_cost_records_valid
    cost_records.flat_map { _1.reject(&:valid?) }.each do |model|
      model.errors.full_messages.each { errors.add(:base, _1) }
    end
  end

  def save_participations
    return true unless @participations_attributes

    @participations_attributes.all? do |id, attrs|
      participation = participation_by_id[id.to_i]
      participation.update(attrs)
    end
  end

  def save_cost_records
    cost_records.each do |collection|
      collection.each { _1.marked_for_destruction? ? _1.destroy! : _1.save! }
    end
  end

  def participation_by_id
    @participation_by_id ||= participations.index_by(&:id)
  end

  def cost_records
    [@revenues, @expenditures, @receipts].compact
  end

  def build_records(attrs, collection:, fixed_attributes: {})
    attrs.values.map do |values|
      record = if values[:id].present?
        collection.index_by(&:id).transform_keys(&:to_s).fetch(values[:id].to_s)
      else
        collection.build
      end

      if ActiveRecord::Type::Boolean.new.cast(values[:_destroy])
        record.mark_for_destruction
      else
        record.assign_attributes(values.except(:id, :_destroy).merge(fixed_attributes))
      end
      record
    end
  end
end
