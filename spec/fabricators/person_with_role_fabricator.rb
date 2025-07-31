# This fabricator is used to create a person with a role in a group.
# It is supposed to create a complete person with all attributes set
# and without data quality issues.
Fabricator(:person_with_role, from: :person_with_address_and_phone) do
  transient :group
  transient :role
  transient :beitragskategorie
  transient :start_on
  transient :end_on

  after_create do |person, transients|
    group = transients[:group]
    role = transients[:role]
    beitragskategorie = transients[:beitragskategorie]
    role_type = group.class.const_get(role)
    Fabricate(
      role_type.sti_name,
      group:,
      person:,
      beitragskategorie:,
      start_on: transients[:start_on] || 1.year.ago,
      end_on: transients[:end_on] || Date.current.end_of_year
    )
  end
end
