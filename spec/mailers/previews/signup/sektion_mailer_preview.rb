# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Signup::SektionMailerPreview < ActionMailer::Preview
  def signup_email
    Signup::SektionMailer.confirmation(Person.first, Group::Sektion.first, "adult")
  end
end
