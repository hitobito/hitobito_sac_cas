# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Groups::SelfInscriptionController
  extend ActiveSupport::Concern

  prepended do
    self.permitted_attrs = [:register_on, :register_as]
    skip_before_action :redirect_to_group_if_necessary
    before_action :redirect_to_person_if_sektion_member?
  end

  def new
    @title = helpers.render_self_registration_title(entry.group_for_title)
  end

  def confirm
    assign_attributes

    if entry.valid?
      render :confirm
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    assign_attributes

    if entry.save!
      send_notification_email
      redirect_with_message(notice: t(".role_saved"))
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def build_entry
    SelfInscription.new(person: person, group: group)
  end

  def ivar_name(_klass)
    :inscription
  end

  def assign_attributes
    attributes = params[:self_inscription]&.permit(permitted_attrs)
    entry.assign_attributes(attributes || {})
  end

  def redirect_to_person_if_sektion_member?
    if self_registration_active? && entry.active_in_sektion?
      redirect_with_message(notice: t(".membership_role_exists"))
    end
  end
end
