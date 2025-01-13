#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Changelogs::FooterLinkBuilder
  delegate :current_user, :can?, to: :template

  def render
    if defined?(template.current_user) && current_user && can?(:index, ChangelogEntry)
      super
    else
      safe_join([version_label(display_as_link: false)])
    end
  end
end
