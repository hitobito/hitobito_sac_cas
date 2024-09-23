# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PeopleController
  extend ActiveSupport::Concern

  LOOKUP_PREFIX = "people/neuanmeldungen"

  prepended do
    before_action :set_lookup_prefixes
    before_update :check_birthday
  end

  def list_filter_args
    return super unless group.root? && no_filter_active?

    Person::Filter::NeuanmeldungenList.new(group, current_user).filter_params
  end

  private

  def registrations_for_approval?
    group.is_a?(Group::SektionsNeuanmeldungenSektion)
  end

  def no_filter_active?
    %w[filters filter_id].none? { |k| params[k].present? }
  end

  # If we are on the page of a Group::SektionsNeuanmeldungenNv, we want to
  # render the templates from the people/neuanmeldungen folder.
  # Somehow the lookup_context.prefixes is not reset correctly between requests,
  # so we remove the lookup prefix here and add it again only if needed.
  def set_lookup_prefixes
    lookup_context.prefixes -= [LOOKUP_PREFIX]
    lookup_context.prefixes.unshift("people/neuanmeldungen") if registrations_for_approval?
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

  def tabular_params(**)
    super.merge(params.slice(:recipients, :recipient_households).permit!)
  end

  # BIRTHDAY VALIDATION

  def check_birthday
    return if !entry.sac_membership_active? || birthday_year == Person.find(entry.id).birthday.year

    if current_user.backoffice?
      validate_birthday_range
    else
      add_error(:readonly)
    end
  end

  def validate_birthday_range
    max_year = current_year - 6
    min_year = current_year - 120

    if birthday_year >= max_year
      add_error(:must_be_before_year, max_year)
    elsif birthday_year < min_year
      add_error(:must_be_after_year, min_year)
    end
  end

  def add_error(error_type, year = nil)
    if year
      entry.errors.add(:birthday, I18n.t("activerecord.errors.models.person.birthday.#{error_type}", year: year))
    else
      entry.errors.add(:birthday, I18n.t("activerecord.errors.messages.#{error_type}"))
    end
    throw(:abort) # do not save record
  end

  def current_year = Time.current.year

  def birthday_year = params[:person][:birthday].to_date.year
end
