# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::SelfRegistration::Person

  def role
    super.tap do |r|
      # TODO: in a later ticket: what timestamps should we set for created_at and delete_on?
      # https://github.com/hitobito/hitobito_sac_cas/issues/177
      r.created_at = Time.zone.now
      r.delete_on = Time.zone.today.end_of_year
    end
  end

end
