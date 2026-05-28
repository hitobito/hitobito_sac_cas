# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::GroupsHelper
  def format_sac_cas_self_registration_url(entry)
    url = entry.sac_cas_self_registration_url(request.host_with_port)
    link_to(url, url)
  end
end
