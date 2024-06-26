Fabricator(:person_with_role, from: :person) do
  transient :group
  transient :role
  transient :beitragskategorie

  after_create do |person, transients|
    group = transients[:group]
    role = transients[:role]
    beitragskategorie = transients[:beitragskategorie]
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: person, beitragskategorie: beitragskategorie)
  end
end
