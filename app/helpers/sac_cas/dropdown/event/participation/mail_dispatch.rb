# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Dropdown::Event::Participation::MailDispatch
  private

  def custom_content_keys
    if (participation.roles.map(&:type) & Event::Course::LEADER_ROLES).any?
      Event::Participation::MANUALLY_SENDABLE_LEADERSHIP_MAILS
    else
      Event::Participation::MANUALLY_SENDABLE_PARTICIPANT_MAILS
    end
  end
end
