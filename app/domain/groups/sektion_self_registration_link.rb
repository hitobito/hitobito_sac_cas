# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SektionSelfRegistrationLink
  delegate :group_self_registration_url,
            :group_self_registration_path,
    to: 'Rails.application.routes.url_helpers'

  def initialize(sektion, host)
    @sektion = sektion
    @host = host
  end

  def url
    return unless neuanmeldungen_id = neuanmeldungen_sektion_id || neuanmeldungen_nv_id
    return group_self_registration_path(group_id: neuanmeldungen_id) if @host.blank?

    group_self_registration_url(host: @host, group_id: neuanmeldungen_id)
  end

  private

  def neuanmeldungen_nv_id
    @neuanmeldungen_nv_id ||=
      @sektion
      .children
      .find_by(type: "Group::SektionsNeuanmeldungenSektion")
      .try(:id)
  end

  def neuanmeldungen_sektion_id
    @neuanmeldungen_sektion_id ||=
      @sektion
      .children
      .find_by(type: Group::SektionsNeuanmeldungenSektion)
      .try(:id)
  end
end
