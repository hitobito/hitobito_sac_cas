#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Event::ApprovalCommissionResponsibilityForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :group
  attr_writer :event_approval_commission_responsibilities

  def save!
    ActiveRecord::Base.transaction do
      event_approval_commission_responsibilities.each(&:save!)
    end
    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:base, :invalid_event_comission_responsibilities)
    false
  end

  def event_approval_commission_responsibilities_attributes=(params)
    @event_approval_commission_responsibilities = params.values.map do |attributes|
      record = if attributes[:id].present?
        Event::ApprovalCommissionResponsibility.find(attributes[:id])
      else
        group.event_approval_commission_responsibilities.build
      end
      record.assign_attributes(attributes)
      record
    end
  end

  def event_approval_commission_responsibilities
    @event_approval_commission_responsibilities ||= find_or_build_responsibilties
  end

  def grouped_event_approval_commission_responsibilities
    @grouped_entries ||= event_approval_commission_responsibilities.group_by(&:target_group)
      .transform_values {
      _1.group_by(&:discipline)
    }
  end

  private

  def find_or_build_responsibilties
    existing_entries = group.event_approval_commission_responsibilities
      .includes(target_group: :translations, discipline: :translations)
      .index_by { [_1.target_group_id, _1.discipline_id, _1.subito] }

    Event::TargetGroup.main.list.flat_map do |target_group|
      Event::Discipline.main.list.flat_map do |discipline|
        [true, false].map do |subito|
          existing_entries[[target_group.id, discipline.id, subito]] ||
            build_responsibilty(group, target_group, discipline, subito)
        end
      end
    end
  end

  def build_responsibilty(group, target_group, discipline, subito)
    group.event_approval_commission_responsibilities.build(target_group: target_group,
      discipline: discipline, subito: subito)
  end
end
