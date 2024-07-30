# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup::AboMagazin
  class IssuesFromField < Wizards::Step
    attribute :issues_from, :date, default: -> { Time.zone.today }

    validates :issues_from, timeliness: {on_or_after: -> { Time.zone.today }, type: :date}
  end
end
