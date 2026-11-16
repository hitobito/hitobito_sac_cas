# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class MigrateTourContactInfoPlaceholders < ActiveRecord::Migration[8.0]
  def up
    migrator = Migrations::ContactInfoPlaceholderMigrator.new
    say_with_time("replace contact placeholders with {contact-info}") do
      migrator.rewrite_placeholders
    end

    say_with_time("reset section templates using contact placeholders") do
      migrator.reset_section_templates
    end
  end

  def down
  end
end
