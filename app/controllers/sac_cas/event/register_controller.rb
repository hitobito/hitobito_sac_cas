# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Event::RegisterController
  def save_entry
    if super
      person.send_reset_password_instructions
      Group::AboBasicLogin::BasicLogin.create!(group: abo_basic_login_group, person: person)
    end
  end

  def abo_basic_login_group
    Group::AboBasicLogin.where(layer_group_id: Group.root_id).first
  end
end
