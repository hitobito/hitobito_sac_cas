# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PeopleController
  extend ActiveSupport::Concern

  LOOKUP_PREFIX = 'people/neuanmeldungen'

  prepended do
    before_action :set_lookup_prefixes

    after_save :assign_roles_for_newly_created_managed_people
  end

  def list_filter_args
    return super unless group.root? && no_filter_active?

    Person::Filter::NeuanmeldungenList.new(group, current_user).filter_params
  end

  def update(options = {}, &block)
    assign_attributes
    if validate_new_manageds
      updated = with_callbacks(:update, :save) { save_entry }
      respond_with(entry, options.reverse_merge(success: updated, location: return_path), &block)
    else
      render :edit
    end
  end

  def assign_roles_for_newly_created_managed_people
    return unless newly_created_managed_people.any?
    
    Role.transaction do
      cloneable_mitglied_roles.each do |role|
        newly_created_managed_people.each do |p|
          Role.create!(person: p,
                       group: role.group,
                       type: role.type,
                       beitragskategorie: role.beitragskategorie,
                       created_at: Time.zone.now,
                       delete_on: role.delete_on)
        end
      end
    end
  end

  def validate_new_manageds
    assert_entry_age! && assert_new_manageds_age!
  end

  def cloneable_mitglied_roles
    entry.roles.where(type: SacCas::MITGLIED_ROLES, beitragskategorie: 'familie')
  end

  def newly_created_managed_people
    @newly_created_managed_people ||= new_manageds.select(&:new_record?)
  end

  private

  def assert_entry_age!
    age_range_adult = SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT
    return true if age_range_adult.include?(entry.years)

    entry.errors.add(:base, :too_young_for_managed)
    false
  end

  def assert_new_manageds_age!
    age_range_youth = SacCas::Beitragskategorie::Calculator::AGE_RANGE_YOUTH
    return true if newly_created_managed_people.all? { age_range_youth.include?(_1.years) }

    entry.errors.add(:base, :new_managed_age_invalid)
    false
  end

  def registrations_for_approval?
    group.is_a?(Group::SektionsNeuanmeldungenSektion)
  end

  def no_filter_active?
    %w(filters filter_id).none? { |k| params[k].present? }
  end

  # If we are on the page of a Group::SektionsNeuanmeldungenNv, we want to
  # render the templates from the people/neuanmeldungen folder.
  # Somehow the lookup_context.prefixes is not reset correctly between requests,
  # so we remove the lookup prefix here and add it again only if needed.
  def set_lookup_prefixes
    lookup_context.prefixes -= [LOOKUP_PREFIX]
    lookup_context.prefixes.unshift('people/neuanmeldungen') if registrations_for_approval?
  end

  def find_entry
    Person.with_membership_years.find(super.id)
  end

  def model_scope
    super.with_membership_years
  end

  def filter_entries
    super.with_membership_years
  end

  def prepare_entries(entries)
    super.includes(:primary_group)
  end

end
