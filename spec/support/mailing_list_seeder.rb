# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class MailingListSeeder
  def self.seed!
    original_quiet_setting = SeedFu.quiet
    SeedFu.quiet = true
    eval Pathname.new(File.dirname(__FILE__)).join("../../db/seeds/mailing_lists.rb").read
  ensure
    SeedFu.quiet = original_quiet_setting
  end
end
