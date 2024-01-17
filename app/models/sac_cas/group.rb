# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Group
  extend ActiveSupport::Concern

  included do
    # Define additional used attributes
    # self.used_attributes += [:website, :bank_account, :description]
    # self.superior_attributes = [:bank_account]

    root_types Group::SacCas

    alias_method :group_id, :id
  end

  def sektion_or_ortsgruppe?
    [Group::Sektion, Group::Ortsgruppe].any? { |c| is_a?(c) }
  end

  def preferred_primary?
    Groups::Primary::GROUP_TYPES.include?(type)
  end
end
