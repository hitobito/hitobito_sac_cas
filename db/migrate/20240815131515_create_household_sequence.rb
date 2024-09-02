
class CreateHouseholdSequence < ActiveRecord::Migration[6.1]
  def up
    highest_number_without_prefix = execute("SELECT MAX(sub.household_key::integer) FROM (SELECT household_key from people
where (household_key IS NOT NULL OR household_key != '') AND household_key NOT LIKE 'F%') as sub").getValue(0, 0)

    highest_number_with_prefix = execute("SELECT MAX(REPLACE(household_key, 'F', '')::integer) FROM people
where household_key LIKE 'F%';").getValue(0, 0)

    current_household_key = ([highest_number_without_prefix, highest_number_with_prefix].max || 0) + 1

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