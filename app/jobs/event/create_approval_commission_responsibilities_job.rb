# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::CreateApprovalCommissionResponsibilitiesJob < BaseJob
  self.parameters = [:discipline_id, :target_group_id, :freigabe_komitee_group_id]

  attr_reader :discipline_id, :target_group_id, :freigabe_komitee_group_id

  def initialize(discipline: nil, target_group: nil, freigabe_komitee_group: nil)
    @discipline_id = discipline&.id
    @target_group_id = target_group&.id
    @freigabe_komitee_group_id = freigabe_komitee_group&.id

    raise "must pass exactly one argument" unless [discipline, target_group,
      freigabe_komitee_group].compact.size == 1
  end

  def perform
    Event::ApprovalCommissionResponsibility.transaction do
      relevant_sektionen_and_ortsgruppen.find_each do |group|
        freigabe_komitee_id = freigabe_komitee_group_id || find_target_freigabe_komitee(group).id
        relevant_disciplines.find_each do |discipline|
          relevant_target_groups.find_each do |target_group|
            [true, false].each do |subito|
              group.event_approval_commission_responsibilities.create!(discipline:,
                target_group:,
                subito:,
                freigabe_komitee_id:)
            end
          end
        end
      end
    end
  end

  private

  def find_target_freigabe_komitee(layer)
    Group::FreigabeKomitee.left_joins(:event_approval_commission_responsibilities)
      .where(layer_group: layer)
      .group(:id)
      .order("COUNT(event_approval_commission_responsibilities.id) DESC")
      .first
  end

  def relevant_disciplines
    return Event::Discipline.where(id: discipline_id) if discipline_id.present?

    Event::Discipline.main.list
  end

  def relevant_target_groups
    return Event::TargetGroup.where(id: target_group_id) if target_group_id.present?

    Event::TargetGroup.main.list
  end

  def relevant_sektionen_and_ortsgruppen
    Group.where(type: [Group::Sektion, Group::Ortsgruppe].map(&:sti_name))
      .where(id: layer_ids_of_freigabe_komitees)
  end

  def layer_ids_of_freigabe_komitees
    scope = Group::FreigabeKomitee.all
    scope = scope.where(id: freigabe_komitee_group_id) if freigabe_komitee_group_id.present?
    scope.select(:layer_group_id)
  end
end
