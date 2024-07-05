# frozen_string_literal: true

#
#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::MountedAttrs::EnumSelect
  private

  def option_label(option)
    sektion_canton? ? Cantons.full_name(option) : super
  end

  def sektion_canton?
    config.attr_name.to_sym == :section_canton
  end
end
