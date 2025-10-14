# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module TableDisplays::People
  class SacRemarkSectionColumn < TableDisplays::PublicColumn
    def required_model_attrs(attr)
      [:sac_remark_section_1, :sac_remark_section_2, :sac_remark_section_3, :sac_remark_section_4,
        :sac_remark_section_5]
    end

    def required_permission(attr)
      :manage_section_remarks
    end

    def sort_by(attr)
      nil
    end
  end
end
