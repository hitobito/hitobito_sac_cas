# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonAbility
  extend ActiveSupport::Concern

  included do
    on(Person) do
      general(:primary_group).not_herself_sektion
    end
  end

  def not_herself_sektion
    Groups::Primary::GROUP_TYPES.include?(person.primary_group.type) ? !herself : true
  end
end
