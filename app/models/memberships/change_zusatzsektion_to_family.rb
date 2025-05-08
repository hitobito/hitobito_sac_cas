class Memberships::ChangeZusatzsektionToFamily
  def initialize(role)
    @role = role
  end

  def save!
    Memberships::FamilyMutation.new(@role.person).change_zusatzsektion_to_family!(@role)
  end
end
