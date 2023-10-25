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

end
