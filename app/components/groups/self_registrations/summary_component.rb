# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Groups::SelfRegistrations::SummaryComponent < Groups::SelfRegistrations::BaseComponent

  def self.title
    I18n.t("sac_cas.groups.self_registration.form.summary_title")
  end

end
