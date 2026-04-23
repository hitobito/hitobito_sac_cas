# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Ortsgruppe < Group
  include Groups::Sektionsartig

  after_create :init_section_custom_contents

  private

  def init_section_custom_contents
    Groups::InitSacSectionCustomContentsJob.new(self).enqueue!
  end
end
