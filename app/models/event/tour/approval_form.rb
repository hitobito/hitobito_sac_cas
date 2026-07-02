# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::ApprovalForm
  include ActiveModel::Model

  EMAIL_RECEIVER_OPTIONS = [
    :responsible_people,
    :responsible_people_and_assigned_freigabe_komitees,
    :none
  ].freeze

  attr_reader :event, :user, :komitee_approvals, :self_approval, :pruefer_roles, :changed_approvals
  attr_accessor :receiver_option

  delegate :internal_comment, :internal_comment=, to: :event

  def initialize(event, user)
    @event = event
    @user = user
    @receiver_option = EMAIL_RECEIVER_OPTIONS.first
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
    success = event.transaction do
      case action
      when "approve" then update_approved
      when "reject" then update_rejected
      end

      raise ActiveRecord::Rollback unless event.save
      true
    end

    send_approval_emails(action) if success
    success
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

  def reset_approvals
    find_self_approval&.mark_for_destruction
    remove_not_responsible_komitee_approvals
    event.state = :approved if all_approved?
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
    activities_target_groups = composer.fetch_freigabe_komitee_activities_target_groups(komitees)
    komitees.map do |freigabe_komitee|
      build_komitee_approval(
        freigabe_komitee,
        activities_target_groups.fetch(freigabe_komitee.id, [])
      )
    end
  end

  def build_komitee_approval(freigabe_komitee, activities_target_groups)
    Event::Tour::KomiteeApproval.new(
      freigabe_komitee:,
      approval_kinds:,
      approvals: find_komitee_approvals(freigabe_komitee),
      activities_target_groups: sorted_activities_target_groups(activities_target_groups),
      responsible_kinds: responsible_kinds(freigabe_komitee)
    )
  end

  def find_self_approval
    event.approvals.find { |a| a.freigabe_komitee_id.nil? }
  end

  def find_komitee_approvals(freigabe_komitee)
    event.approvals.select { |a| a.freigabe_komitee_id == freigabe_komitee.id }
  end

  def sorted_activities_target_groups(activities_target_groups)
    activities_target_groups.sort_by { |activity, target_group|
      [activity.to_s, target_group.to_s]
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

  def send_approval_emails(action)
    return if no_email?

    case action
    when "approve" then all_approved? ? send_granted_email : send_required_email
    when "reject" then send_rejected_email
    end
  end

  def send_granted_email
    Event::TourApprovalMailer.granted(event, event.creator, event.contact).deliver_later
  end

  def send_rejected_email
    cc = [event.contact]
    cc += email_receivers_include_komitees? ? composer.all_pruefers.to_a : [user]
    Event::TourApprovalMailer.rejected(event, event.creator, cc.compact).deliver_later
  end

  def send_required_email
    cc = [event.contact, event.creator]
    cc += composer.remaining_pruefers.to_a if email_receivers_include_komitees?
    Event::TourApprovalMailer.required(
      event, composer.next_relevant_pruefer.to_a, cc.compact
    ).deliver_later
  end

  def email_receivers_include_komitees?
    receiver_option.to_sym == :responsible_people_and_assigned_freigabe_komitees
  end

  def no_email?
    receiver_option.nil? || receiver_option.to_s == "none"
  end

  def remove_not_responsible_komitee_approvals
    komitee_ids = komitee_approvals.map(&:freigabe_komitee_id)
    event.approvals.each do |a|
      unless komitee_ids.include?(a.freigabe_komitee_id)
        a.mark_for_destruction
      end
    end
  end

  def composer
    @composer ||= Events::Tours::ApprovalComposer.new(event, nil)
  end

  def approval_kinds
    @approval_kinds ||= Event::ApprovalKind.list.without_deleted
  end
end
