class CreateHouseholdSequence < ActiveRecord::Migration[6.1]
  def up
    max_household_key = execute("SELECT MAX(household_key::integer) FROM people")

    start_value = max_household_key + 1

    execute <<-SQL
      CREATE SEQUENCE household_sequence
      START WITH #{start_value}
      INCREMENT BY 1
      NO MINVALUE
      NO MAXVALUE
      CACHE 1;
    SQL
  end

  def down
    execute <<-SQL
      DROP SEQUENCE IF EXISTS household_sequence;
    SQL
  end
end
