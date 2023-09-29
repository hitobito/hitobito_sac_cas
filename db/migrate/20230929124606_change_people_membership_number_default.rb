# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class ChangePeopleMembershipNumberDefault < ActiveRecord::Migration[6.1]
  MIN_GENERATED_MEMBERSHIP_NUMBER = 500_000

  def up
    # Create a sequence to generate unique membership numbers,
    # starting from MIN_GENERATED_MEMBERSHIP_NUMBER
    execute <<-SQL
      CREATE SEQUENCE people_membership_number_seq START #{MIN_GENERATED_MEMBERSHIP_NUMBER};
    SQL

    # Update existing records without a membership_number with values from the sequence
    execute <<-SQL
      UPDATE people SET membership_number = NEXT VALUE FOR people_membership_number_seq WHERE membership_number IS NULL;
    SQL

    # Set the sequence as default value for the membership_number column and make it NOT NULL.
    # This will automatically generate a new membership_number for new records
    # and will not overwrite existing membership numbers.
    execute <<-SQL
      ALTER TABLE people MODIFY COLUMN membership_number INT NOT NULL DEFAULT (NEXT VALUE FOR people_membership_number_seq);
    SQL

    # Add a unique index on the membership_number column
    add_index :people, :membership_number, unique: true
  end

  def down
    remove_index :people, :membership_number
    change_column_null :people, :membership_number, true
    change_column_default :people, :membership_number, nil
    execute <<-SQL
      DROP SEQUENCE people_membership_number_seq;
    SQL
  end
end
