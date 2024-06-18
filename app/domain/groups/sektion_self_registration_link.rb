# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SektionSelfRegistrationLink
  delegate :group_self_registration_url,
           :group_self_registration_path,
           to: 'Rails.application.routes.url_helpers'

  def initialize(group, host)
    @sektion = group
    @host = host
  end

  def url
    return unless @sektion
    return group_self_registration_path(group_id: @sektion.id) if @host.blank?

    group_self_registration_url(host: @host, group_id: @sektion.id)
  end
end
