class People::ExternalInvoicePayedJob < BaseJob
  def initialize(person_id, group_id, year)
    @membership_manager = ExternalInvoice::SacMembership::MembershipManager.new(Person.find(person_id), Group.find(group_id), year)
  end

  def perform
    @membership_manager.update_membership_status
  end
end
