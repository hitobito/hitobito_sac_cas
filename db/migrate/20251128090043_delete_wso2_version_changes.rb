# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class DeleteWso2VersionChanges < ActiveRecord::Migration[8.0]
  REGEXP = "\nwso2_legacy_password_hash:.*wso2_legacy_password_salt:.*\n-\n"
  def change
    log_counts("object_changes LIKE '%wso2%'")
    log_counts("object_changes NOT LIKE '%wso2%'")
    PaperTrail::Version.where("object_changes LIKE '---\nwso2%'").delete_all

    log_counts("object_changes ~ '#{REGEXP}'")
    PaperTrail::Version.where("object_changes ~ '#{REGEXP}'")
      .update_all(object_changes: Arel.sql("REGEXP_REPLACE(object_changes, '#{REGEXP}', '','g')"))

    say "Updated counts .. "
    log_counts("object_changes ~ '#{REGEXP}'")
    log_counts("object_changes NOT LIKE '%wso2%'")
    log_counts("object_changes LIKE '%wso2%'")
  end

  private

  def log_counts(condition)
    counts = PaperTrail::Version.where(condition).count
    say "Counts for #{condition}: #{counts}"
  end
end
