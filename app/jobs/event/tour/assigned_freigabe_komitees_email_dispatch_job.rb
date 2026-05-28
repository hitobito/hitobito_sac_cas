# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob < Event::Tour::EmailDispatchJob
  private

  def recipients
    composer.all_pruefers
  end

  def composer = @composer ||= Events::Tours::ApprovalComposer.new(tour, nil)
end
