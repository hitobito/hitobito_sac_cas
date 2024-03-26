# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::RoleDecorator
  extend ActiveSupport::Concern

  def for_oauth
    {
      **super,
      layer_group_id: object.group.layer_group_id
    }
  end

end
