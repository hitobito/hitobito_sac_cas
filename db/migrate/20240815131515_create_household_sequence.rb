
class CreateHouseholdSequence < ActiveRecord::Migration[6.1]
  def up
    result = execute("SELECT COALESCE(MAX(household_key::integer) + 1, 1) FROM people")
    current_household_key = result.values[0][0].to_i

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