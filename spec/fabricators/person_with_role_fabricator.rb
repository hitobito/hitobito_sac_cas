Fabricator(:person_with_role, from: :person) do
  transient :group
  transient :role
  transient :attrs

  #binding.irb

  after_create do |person, transients|
    group = transients[:group]
    role = transients[:role]
    attrs = transients[:attrs] || {}
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: person, **attrs)
  end
end
