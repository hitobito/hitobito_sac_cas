# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PersonAbility
  extend ActiveSupport::Concern

  included do
    on(::Person) do
      general(:primary_group).only_herself_if_not_preferred_primary_role
    end
  end

  def only_herself_if_not_preferred_primary_role
    primary = Groups::Primary.new(person)
    !(primary.preferred_exists? && herself)
  end
end
