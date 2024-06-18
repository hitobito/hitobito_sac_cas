# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Groups::WithNeuanmeldung
  extend ActiveSupport::Concern

  ORDERED_NEUANMELDUNG_GROUPS = [
    Group::SektionsNeuanmeldungenSektion.sti_name,
    Group::SektionsNeuanmeldungenNv.sti_name
  ].freeze

  def group_for_neuanmeldung
    @group_for_neuanmeldung ||= children_without_deleted
                                .without_archived
                                .where(type: ORDERED_NEUANMELDUNG_GROUPS)
                                .min_by { |g| ORDERED_NEUANMELDUNG_GROUPS.index(g.type) }
  end

  def sac_cas_self_registration_url(host)
    Groups::SektionSelfRegistrationLink.new(group_for_neuanmeldung, host).url
  end
end
