module Migrations
  class MakeTerminations
    # 464219,1,false,true
    # 494882,1,false,true
    # 509099,1,true,true
    DATA = <<~TEXT
      id,termination_reason_id,data_retention_consent,send_email
      148888,5,false,true
      322912,4,false,true
      196336,2,false,false
      274218,1,false,true
      276138,2,false,false
      439105,1,true,true
      315943,1,false,true
      325711,1,false,true
      372865,1,true,true
      464218,1,false,true
      485343,1,false,true
      494881,1,false,true
    TEXT

    def perform
      PaperTrail.request.whodunnit = "Make Terminations"
      Person.transaction do
        csv.each do |row|
          terminate(row)
        end
        fail "ouch"
      end
    end

    def csv
      @csv ||= CSV.parse(DATA, headers: true)
    end

    def terminate(row)
      puts "Terminating #{row}"
      terminate_on = Time.zone.yesterday
      role = Group::SektionsMitglieder::Mitglied.find_by!(person_id: row["id"])
      termination = Memberships::TerminateSacMembership.new(
        role,
        terminate_on:,
        data_retention_consent: bool(row["data_retention_consent"]),
        termination_reason_id: row["termination_reason_id"]
      )
      termination.save
      send_confirmation_mail(role, terminate_on, bool(row["send_email"]))
    end

    def bool(val) = ActiveModel::Type::Boolean.new.cast(val)

    def send_confirmation_mail(role, terminate_on, inform_mitglied)
      Memberships::TerminateMembershipMailer.terminate_membership(
        role.person,
        role.layer_group,
        terminate_on,
        inform_mitglied
      ).deliver_later
    end
  end
end
