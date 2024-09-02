
class CreateHouseholdSequence < ActiveRecord::Migration[6.1]
  def up
    highest_number = execute("SELECT MAX(REPLACE(household_key, 'F', '')::integer) FROM people
where household_key LIKE 'F%';").getValue(0, 0)

    current_household_key = (highest_number || 0) + 1

    execute <<-SQL
      CREATE SEQUENCE household_sequence
      START WITH #{current_household_key}
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