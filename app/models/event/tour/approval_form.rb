# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ApprovalForm
  include ActiveModel::Model

  attr_reader :event, :user, :komitee_approvals, :self_approval, :pruefer_roles, :changed_approvals

  delegate :internal_comment, :internal_comment=, to: :event

  def initialize(event, user)
    @event = event
    @user = user
    @pruefer_roles = preload_pruefer_roles
    @komitee_approvals = build_komitee_approvals
    @self_approval = find_self_approval if @komitee_approvals.blank?
  end

  def komitee_approvals_attributes=(attributes)
    list = attributes.is_a?(Hash) ? attributes.values : attributes
    list.each do |attrs|
      komitee_approvals
        .find { |ka| ka.freigabe_komitee_id == attrs[:freigabe_komitee_id].to_i }
        &.assign_attributes(attrs.except(:freigabe_komitee_id))
    end
  end

  def save(action)
    event.transaction do
      case action
      when "approve" then update_approved
      when "reject" then update_rejected
      end
      event.save.tap do |success|
        raise ActiveRecord::Rollback unless success
      end
    end
  end

  def approvable?
    event.review? && komitee_approvals.any?(&:approvable?)
  end

  def all_approved?
    komitee_approvals.all?(&:all_approved?)
  end

  def pre_check_approvable
    komitee_approvals.each(&:pre_check_approvable)
  end

  private

  def update_approved
    update_approvals(true)
    event.state = :approved if all_approved?
  end

  def update_rejected
    update_approvals(false)
    event.state = :draft if changed_approvals.present?
  end

  def update_approvals(approved) # rubocop:disable Metrics/CyclomaticComplexity
    @changed_approvals = komitee_approvals.flat_map do |komitee_approval|
      previous_checked = true
      komitee_approval.approval_kind_approvals.filter_map do |aka|
        next if !aka.approvable || aka.approval&.approved || !previous_checked

        if aka.checked
          update_approval(aka, komitee_approval.freigabe_komitee, approved)
        else
          previous_checked = false
          nil
        end
      end
    end
  end

  def update_approval(kind_approval, freigabe_komitee, approved)
    kind_approval.approval ||= event.approvals.build(
      freigabe_komitee: freigabe_komitee,
      approval_kind: kind_approval.approval_kind
    )
    kind_approval.approval.update!(approved:, creator: user, created_at: Time.zone.now)
    kind_approval.approval
  end

  def build_komitee_approvals
    komitees = composer.relevant_freigabe_komitees.list
    disciplines_target_groups = composer.fetch_freigabe_komitee_disciplines_target_groups(komitees)
    komitees.map do |freigabe_komitee|
      build_komitee_approval(
        freigabe_komitee,
        disciplines_target_groups.fetch(freigabe_komitee.id, [])
      )
    end
  end

  def build_komitee_approval(freigabe_komitee, disciplines_target_groups)
    Event::Tour::KomiteeApproval.new(
      freigabe_komitee:,
      approval_kinds:,
      approvals: find_komitee_approvals(freigabe_komitee),
      disciplines_target_groups: sorted_disciplines_target_groups(disciplines_target_groups),
      responsible_kinds: responsible_kinds(freigabe_komitee)
    )
  end

  def find_self_approval
    event.approvals.find { |a| a.freigabe_komitee_id.nil? }
  end

  def find_komitee_approvals(freigabe_komitee)
    event.approvals.select { |a| a.freigabe_komitee_id == freigabe_komitee.id }
  end

  def sorted_disciplines_target_groups(disciplines_target_groups)
    disciplines_target_groups.sort_by { |discipline, target_group|
      [discipline.to_s, target_group.to_s]
    }
  end

  def responsible_kinds(freigabe_komitee)
    pruefer_roles.select { |r| r.group_id == freigabe_komitee.id }.flat_map(&:approval_kinds).uniq
  end

  def preload_pruefer_roles
    return [] unless event.review?

    pruefer_roles = user.roles.select { |r| r.is_a?(Group::FreigabeKomitee::Pruefer) }
    ActiveRecord::Associations::Preloader
      .new(records: pruefer_roles, associations: :approval_kinds)
      .call
    pruefer_roles
  end

  def composer
    @composer ||= Events::Tours::ApprovalComposer.new(event, nil)
  end

  def approval_kinds
    @approval_kinds ||= Event::ApprovalKind.list.without_deleted
  end
end
