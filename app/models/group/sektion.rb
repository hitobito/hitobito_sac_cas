# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Sektion < Group
  include Groups::Sektionsartig

  possible_children << Group::Ortsgruppe

  has_and_belongs_to_many :section_offerings, foreign_key: :group_id

  def sorting_name
    display_name.delete_prefix("SAC ").delete_prefix("CAS ")
  end
end
