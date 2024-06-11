module Memberships::JoinZusatzsektion
  include ActiveModel::Model
  include ActiveModel::Validations

  def initialize(person, sektion, family_membership)
  end

  validates_presence_of :person, :sektion
  validate :sektion_is_sektion_or_ortsgruppe # => validation message: 'ist keine Sektion/Ortsgruppe'
  validate :person_is_sac_member # => validation message: 'muss SAC Mitglied sein'
  validate :person_is_not_already_member_of_sektion # => validation message: 'ist bereits Mitglied der Sektion'
  validate :person_is_family_member, if: :family_membership # => validation message: 'ist kein Familienmitglied'

  def affected_people
    return [person] unless family_membership
    person.sac_family_member? ? person.sac_family.family_members : [person]
  end

  def roles
    @roles ||= affected_people.map {|p| build_role(p) }
  end

  def valid?
    super && roles.all(&:valid?)
  end

  def save!
    raise 'not valid' unless valid?
    person.transaction do
      roles.each(&:save!)
    end
  end

  private

  def build_role(person)
    # build neuanmeldung role in correct neuanmeldung group of sektion
  end

end
