# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::ChangelogHelper
  def render_changelog_link
    if defined?(current_user) && current_user && can?(:index, ChangelogEntry)
      safe_join([collapse_toggle_link, version_label, detail_info_div])
    else
      safe_join([version_label(display_as_link: false)])
    end
  end
end
