# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::Tour do
  subject(:tour) { events(:section_tour) }

  describe "validations" do
    shared_examples "presence validation for draft attributes" do |attribute:, association: false|
      it "validates presence of #{attribute} in state ready" do
        tour.state = :draft
        tour.send(:"#{attribute}=", (association ? [] : nil))
        tour.state = :review
        expect(tour).not_to be_valid
        expect(tour.errors[attribute]).to eq ["muss ausgefüllt werden"]
      end

      it "does not validate presence of #{attribute} in state draft" do
        tour.state = :draft
        expect(tour).to be_valid
      end
    end

    shared_examples "readonly for draft attributes" do |attribute:|
      it "#{attribute} is readonly in state review" do
        tour.update!(state: :review)
        tour.send(:"#{attribute}=", new_valid_value)
        tour.save!
        expect(tour.reload.send(attribute)).not_to eq new_valid_value
      end

      it "#{attribute} is not readonly in state draft" do
        tour.update!(state: :draft)
        tour.send(:"#{attribute}=", new_valid_value)
        tour.save!
        expect(tour.reload.send(attribute)).to eq new_valid_value
      end
    end

    describe "subito" do
      let(:new_valid_value) { true }

      it_behaves_like "readonly for draft attributes", attribute: :subito
    end

    describe "season" do
      let(:new_valid_value) { "winter" }

      it_behaves_like "presence validation for draft attributes", attribute: :season
      it_behaves_like "readonly for draft attributes", attribute: :season
    end

    describe "fitness requirement" do
      let(:new_valid_value) { event_fitness_requirements(:e) }

      it_behaves_like "presence validation for draft attributes", attribute: :fitness_requirement
      it_behaves_like "readonly for draft attributes", attribute: :fitness_requirement
    end

    describe "activities" do
      let(:new_valid_value) { [event_activities(:bergtour)] }

      it_behaves_like "presence validation for draft attributes", attribute: :activities, association: true
      it_behaves_like "readonly for draft attributes", attribute: :activities
    end

    describe "target_groups" do
      let(:new_valid_value) { [event_target_groups(:familien)] }

      it_behaves_like "presence validation for draft attributes", attribute: :target_groups, association: true
      it_behaves_like "readonly for draft attributes", attribute: :target_groups
    end

    describe "technical_requirements" do
      let(:new_valid_value) { [event_technical_requirements(:wandern_t2)] }

      it_behaves_like "presence validation for draft attributes", attribute: :technical_requirements, association: true
      it_behaves_like "readonly for draft attributes", attribute: :technical_requirements

      it "is valid if matching a discplines technical requirment" do
        tour.association(:technical_requirements).target = [event_technical_requirements(:wandern)]

        expect(tour).to be_valid
      end

      it "is valid if parent is matching activities technical requirment" do
        tour.association(:technical_requirements).target = [event_technical_requirements(:wandern_t2)]

        expect(tour).to be_valid
      end

      it "is invalid if not matching a technical requirement of the tours activities" do
        tour.association(:technical_requirements).target = [event_technical_requirements(:klettern_9a)]

        expect(tour).not_to be_valid
        expect(tour.errors.full_messages).to eq [
          "Technische Anforderung(en) müssen zu den ausgewählten Aktivitäten gehören"
        ]
      end
    end

    [:price_member, :price_regular, :price_special].each do |category|
      describe category do
        it "may be empty in state approved" do
          tour.state = :approved
          tour.send(:"#{category}=", nil)
          expect(tour).to be_valid
        end

        it "may be empty in state canceled" do
          tour.update!(state: :approved)
          tour.state = :canceled
          tour.send(:"#{category}=", nil)
          expect(tour).to be_valid
        end

        it "may be empty in state canceled if it doesn't apply" do
          tour.update!(state: :approved)
          tour.state = :canceled
          tour.send(:"#{category.to_s.remove("price_")}_may_apply=", false)
          tour.send(:"#{category}=", nil)
          expect(tour).to be_valid
        end

        it "must be present in state published if it applies" do
          tour.state = :published
          tour.send(:"#{category}=", nil)
          expect(tour).not_to be_valid
          expect(tour.errors[category]).to eq ["muss ausgefüllt werden"]
        end
      end
    end

    describe "possible_price_categories" do
      it "returns all price categories that may apply" do
        expect(tour.possible_price_categories).to match_array [:price_regular, :price_special, :price_member]
      end

      it "does not return price category that may not apply" do
        tour.member_may_apply = false

        expect(tour.possible_price_categories).to match_array [:price_regular, :price_special]
      end
    end

    describe "duration_in_hours" do
      it "sets military time (e.g 1430)" do
        tour.duration_in_hours = "1430"

        expect(tour.duration).to eq(870) # 14 * 60 + 30

        tour.duration_in_hours = "140"

        expect(tour.duration).to eq(100) # 1 * 60 + 40
      end

      it "sets decimal hours" do
        tour.duration_in_hours = "6.5"

        expect(tour.duration).to eq(390) # 6 * 60 + 30

        tour.duration_in_hours = "2"

        expect(tour.duration).to eq(120) # 2 * 60
      end

      it "sets hh:mm format" do
        tour.duration_in_hours = "12:20"

        expect(tour.duration).to eq(740) # 12 * 60 + 20

        tour.duration_in_hours = "3:15"

        expect(tour.duration).to eq(195) # 3 * 60 + 15

        tour.duration_in_hours = "4:5"

        expect(tour.duration).to eq(245) # 4 * 60 + 5
      end
    end
  end

  describe "when state changes to published" do
    context "from approved" do
      before do
        tour.update_column(:state, :approved)
      end

      it "does not send email without receiver_options" do
        expect { tour.update!(state: :published) }.not_to change(Delayed::Job, :count)
      end

      it "does not send email when none is selected" do
        tour.receiver_options = ["none"]

        expect { tour.update!(state: :published) }.not_to change(Delayed::Job, :count)
      end

      it "enqueues job for mailing_list_people with publication key" do
        tour.receiver_options = ["mailing_list_people"]

        expect { tour.update!(state: :published) }
          .to change(enqueued_job_for("Event::Tour::MailingListPeopleEmailDispatchJob", :publication), :count).by(1)
          .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :publication), :count).by(1)
      end

      it "enqueues job for assigned_freigabe_komitees with publication key" do
        tour.receiver_options = ["assigned_freigabe_komitees"]

        expect { tour.update!(state: :published) }
          .to change(
            enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :publication), :count
          ).by(1)
          .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :publication), :count).by(1)
      end

      it "enqueues job for leaders with publication key" do
        tour.receiver_options = ["leaders"]

        expect { tour.update!(state: :published) }
          .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :publication), :count).by(1)
          .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :publication), :count).by(1)
      end

      context "subito tour" do
        before do
          tour.update_column(:subito, true)
        end

        it "enqueues job for mailing_list_people with publication_subito key" do
          tour.receiver_options = ["mailing_list_people"]

          expect { tour.update!(state: :published) }
            .to change(enqueued_job_for("Event::Tour::MailingListPeopleEmailDispatchJob", :publication), :count).by(1)
            .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :publication), :count).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with publication_subito key" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :published) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :publication_subito), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :publication_subito), :count
            ).by(1)
        end

        it "enqueues job for leaders with publication_subito key" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :published) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :publication_subito), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :publication_subito), :count
            ).by(1)
        end
      end
    end

    [:ready, :canceled].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "does not send email without receiver_options" do
          expect { tour.update!(state: :published) }.not_to change(Delayed::Job, :count)
        end

        it "does not send email when none is selected" do
          tour.receiver_options = ["none"]

          expect { tour.update!(state: :published) }.not_to change(Delayed::Job, :count)
        end

        it "enqueues job for assigned_freigabe_komitees with back_to_published key" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :published) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :back_to_published), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_published), :count
            ).by(1)
        end

        it "enqueues job for leaders with back_to_published key" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :published) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :back_to_published), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_published), :count
            ).by(1)
        end
      end
    end
  end

  describe "when state changes to ready" do
    let(:participant) { Fabricate(:event_participation, event: tour) }

    context "from published" do
      before do
        tour.update_column(:state, :published)
      end

      it "updates participation state from assigned to summoned" do
        participant.update!(state: :assigned)

        expect { tour.update!(state: :ready) }
          .to change { participant.reload.state }.to(eq("summoned"))
      end

      it "updates participation state from unconfirmed to rejected" do
        participant.update!(state: :unconfirmed)

        expect { tour.update!(state: :ready) }
          .to change { participant.reload.state }.to(eq("rejected"))
      end

      it "updates participation state from applied to rejected" do
        participant.update!(state: :applied)

        expect { tour.update!(state: :ready) }
          .to change { participant.reload.state }.to(eq("rejected"))
      end

      it "does not update participation state to previous state if not assigned, unconfirmed or applied" do
        participant.update_column(:state, :summoned)

        expect { tour.update!(state: :ready) }.not_to change { participant.reload.state }
      end

      it "does not send email without receiver_options" do
        expect { tour.update!(state: :ready) }.not_to change(Delayed::Job, :count)
      end

      it "does not send email when none is selected" do
        tour.receiver_options = ["none"]

        expect { tour.update!(state: :ready) }.not_to change(Delayed::Job, :count)
      end

      it "enqueues job for participants_confirmed with participation_summon key" do
        tour.receiver_options = ["participants_confirmed"]

        expect(tour).to receive(:participant_states).once.and_return(["assigned"])
        expect { tour.update!(state: :ready) }
          .to change(enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :participation_summon), :count).by(1)
          .and change(
            enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :participation_summon), :count
          ).by(1)
      end

      it "enqueues job for participants_unconfirmed with participation_reject key" do
        tour.receiver_options = ["participants_unconfirmed"]

        expect(tour).to receive(:participant_states)
          .once
          .and_return(["unconfirmed", "applied"])
        expect { tour.update!(state: :ready) }
          .to change(enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :participation_reject), :count).by(1)
          .and change(
            enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :participation_reject), :count
          ).by(0)
      end

      it "enqueues job for leaders with participation_summon key" do
        tour.receiver_options = ["leaders"]

        expect { tour.update!(state: :ready) }
          .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :participation_summon), :count).by(1)
          .and change(
            enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :participation_summon), :count
          ).by(1)
      end

      it "enqueues multiple receiver option jobs and the involved people once" do
        tour.receiver_options = ["participants_confirmed", "leaders"]

        expect { tour.update!(state: :ready) }
          .to change(enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :participation_summon), :count).by(1)
          .and change(
            enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :participation_summon), :count
          ).by(1)
          .and change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :participation_summon), :count).by(1)
      end
    end

    [:closed, :canceled].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "updates participation state from annulled to previous state" do
          participant.update_columns(state: :annulled, previous_state: :summoned)

          expect { tour.update!(state: :ready) }
            .to change { participant.reload.state }.to(eq("summoned"))
        end

        it "does not update participation state to previous state if not annuled" do
          participant.update_column(:state, :assigned)

          expect { tour.update!(state: :ready) }.not_to change { participant.reload.state }
        end

        it "does not send email without receiver_options" do
          expect { tour.update!(state: :ready) }.not_to change(Delayed::Job, :count)
        end

        it "does not send email when none is selected" do
          tour.receiver_options = ["none"]

          expect { tour.update!(state: :ready) }.not_to change(Delayed::Job, :count)
        end

        it "enqueues job for assigned_freigabe_komitees" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :ready) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :back_to_ready), :count
            ).by(1)
            .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_ready), :count).by(1)
        end

        it "enqueues job for leaders" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :ready) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :back_to_ready), :count).by(1)
            .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_ready), :count).by(1)
        end

        it "enqueues multiple receiver option jobs and the involved people once" do
          tour.receiver_options = ["assigned_freigabe_komitees", "leaders"]

          expect { tour.update!(state: :ready) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :back_to_ready), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :back_to_ready), :count
            ).by(1)
            .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_ready), :count).by(1)
        end
      end
    end
  end

  describe "when state changes to closed" do
    let(:participant) { Fabricate(:event_participation, event: tour) }

    before do
      tour.update_column(:state, :ready)
    end

    it "updates participation state from summoned to attended" do
      participant.update_column(:state, :summoned)

      expect { tour.update!(state: :closed) }
        .to change { participant.reload.state }.to(eq("attended"))
    end

    it "does not update participation state to attended if not summoned" do
      participant.update_column(:state, :assigned)

      expect { tour.update!(state: :closed) }.not_to change { participant.reload.state }
    end

    it "does not send email without receiver_options" do
      expect { tour.update!(state: :closed) }.not_to change(Delayed::Job, :count)
    end

    it "does not send email when none is selected" do
      tour.receiver_options = ["none"]

      expect { tour.update!(state: :closed) }.not_to change(Delayed::Job, :count)
    end

    it "enqueues job for participants_participated with closing key" do
      tour.receiver_options = ["participants_participated"]

      expect(tour).to receive(:participant_states).once.and_return(["attended"])
      expect { tour.update!(state: :closed) }
        .to change(enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :closing), :count).by(1)
        .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :closing), :count).by(1)
    end

    it "enqueues job for leaders with closing key" do
      tour.receiver_options = ["leaders"]

      expect { tour.update!(state: :closed) }
        .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :closing), :count).by(1)
        .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :closing), :count).by(1)
    end
  end

  describe "when state changes to canceled" do
    let(:participant) { Fabricate(:event_participation, event: tour) }

    [:approved, :published, :ready].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "updates participation state to annulled and sets previous state" do
          participant.update_column(:state, :summoned)

          expect { tour.update!(state: :canceled, canceled_reason: "weather") }
            .to change { participant.reload.state }.to(eq("annulled"))
            .and change { participant.reload.previous_state }.to(eq("summoned"))
        end

        it "does not send email without receiver_options" do
          expect { tour.update!(state: :canceled, canceled_reason: :weather) }.not_to change(Delayed::Job, :count)
        end

        it "does not send email when none is selected" do
          tour.receiver_options = ["none"]

          expect { tour.update!(state: :canceled, canceled_reason: :weather) }.not_to change(Delayed::Job, :count)
        end

        it "enqueues job for participants with weather mail if canceled_reason is weather" do
          tour.receiver_options = ["participants"]

          expect(tour).to receive(:participant_states)
            .once
            .and_return(["unconfirmed", "applied", "assigned", "summoned"])
          expect { tour.update!(state: :canceled, canceled_reason: :weather) }
            .to change(enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :canceled_weather), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_weather), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with weather mail if canceled_reason is weather" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :canceled, canceled_reason: :weather) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :canceled_weather), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_weather), :count
            ).by(1)
        end

        it "enqueues job for leaders with weather mail if canceled_reason is weather" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :canceled, canceled_reason: :weather) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :canceled_weather), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_weather), :count
            ).by(1)
        end

        it "enqueues job for participants with no leader mail if canceled_reason is no_leader" do
          tour.receiver_options = ["participants"]

          expect(tour).to receive(:participant_states)
            .once
            .and_return(["unconfirmed", "applied", "assigned", "summoned"])
          expect { tour.update!(state: :canceled, canceled_reason: :no_leader) }
            .to change(enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :canceled_no_leader), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_no_leader), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with no leader mail if canceled_reason is no_leader" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :canceled, canceled_reason: :no_leader) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :canceled_no_leader), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_no_leader), :count
            ).by(1)
        end

        it "enqueues job for leaders with no leader mail if canceled_reason is no_leader" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :canceled, canceled_reason: :no_leader) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :canceled_no_leader), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_no_leader), :count
            ).by(1)
        end

        it "enqueues job for participants with minimum participants mail if canceled_reason is minimum_participants" do
          tour.receiver_options = ["participants"]

          expect(tour).to receive(:participant_states)
            .once
            .and_return(["unconfirmed", "applied", "assigned", "summoned"])
          expect { tour.update!(state: :canceled, canceled_reason: :minimum_participants) }
            .to change(
              enqueued_job_for("Event::Tour::ParticipantsEmailDispatchJob", :canceled_minimum_participants), :count
            ).by(1)
            .and change(
              enqueued_job_for(
                "Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_minimum_participants
              ), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with minimum participants mail if minimum_participants" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :canceled, canceled_reason: :minimum_participants) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob",
                :canceled_minimum_participants), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob",
                :canceled_minimum_participants), :count
            ).by(1)
        end

        it "enqueues job for leaders with minimum participants mail if canceled_reason is minimum_participants" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :canceled, canceled_reason: :minimum_participants) }
            .to change(
              enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :canceled_minimum_participants), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :canceled_minimum_participants), :count
            ).by(1)
        end
      end
    end
  end

  describe "when state changes to draft" do
    [:review, :published, :approved].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "does not send email without receiver_options" do
          expect { tour.update!(state: :draft) }.not_to change(Delayed::Job, :count)
        end

        it "does not send email when none is selected" do
          tour.receiver_options = ["none"]

          expect { tour.update!(state: :draft) }.not_to change(Delayed::Job, :count)
        end

        it "enqueues job for assigned_freigabe_komitees with back_to_draft key" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :draft) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :back_to_draft), :count
            ).by(1)
            .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_draft), :count).by(1)
        end

        it "enqueues job for leaders with back_to_draft key" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :draft) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :back_to_draft), :count).by(1)
            .and change(enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_draft), :count).by(1)
        end
      end
    end
  end

  describe "when state changes to approved" do
    before do
      Group::FreigabeKomitee::Pruefer.create!(
        group: groups(:bluemlisalp_freigabekomitee),
        person: people(:mitglied),
        approval_kinds: [event_approval_kinds(:professional)]
      )
    end

    [:published, :canceled].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "does not send email without receiver_options" do
          expect { tour.update!(state: :approved) }.not_to change(Delayed::Job, :count)
        end

        it "does not send email when none is selected" do
          tour.receiver_options = ["none"]

          expect { tour.update!(state: :approved) }.not_to change(Delayed::Job, :count)
        end

        it "enqueues job for assigned_freigabe_komitees with back_to_approved key" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect { tour.update!(state: :approved) }
            .to change(
              enqueued_job_for("Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob", :back_to_approved), :count
            ).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_approved), :count
            ).by(1)
        end

        it "enqueues job for leaders with back_to_approved key" do
          tour.receiver_options = ["leaders"]

          expect { tour.update!(state: :approved) }
            .to change(enqueued_job_for("Event::Tour::LeadersEmailDispatchJob", :back_to_approved), :count).by(1)
            .and change(
              enqueued_job_for("Event::Tour::InvolvedPeopleEmailDispatchJob", :back_to_approved), :count
            ).by(1)
        end
      end
    end

    [:draft, :review].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "does not send mail if not self_approval" do
          allow(tour).to receive(:self_approved?).and_return(false)

          expect { tour.update!(state: :approved) }.not_to have_enqueued_mail(Event::TourApprovalMailer, :self_approved)
        end

        it "sends self_approved mail to all pruefers with cc contact and creator" do
          allow(tour).to receive(:self_approved?).and_return(true)

          expect { tour.update!(state: :approved) }
            .to have_enqueued_mail(Event::TourApprovalMailer, :self_approved)
            .with(tour, [people(:mitglied)], [people(:admin), people(:familienmitglied)])
        end
      end
    end
  end

  describe "when state changes to review" do
    before do
      tour.update_column(:state, :draft)
      Group::FreigabeKomitee::Pruefer.create!(
        group: groups(:bluemlisalp_freigabekomitee),
        person: people(:mitglied),
        approval_kinds: event_approval_kinds(:professional, :security, :editorial)
      )
      Group::FreigabeKomitee::Pruefer.create!(
        group: groups(:bluemlisalp_freigabekomitee),
        person: people(:tourenchef),
        approval_kinds: [event_approval_kinds(:editorial)]
      )
    end

    it "sends required mail to next pruefer with cc contact and creator" do
      tour.receiver_options = ["responsible_people"]
      expect { tour.update!(state: :review) }
        .to have_enqueued_mail(Event::TourApprovalMailer, :required)
        .with(tour, [people(:mitglied)], [people(:admin), people(:familienmitglied)])
    end

    it "sends required mail to next pruefer with cc contact and creator and all other pruefers" do
      tour.receiver_options = ["responsible_people_and_assigned_freigabe_komitees"]
      expect { tour.update!(state: :review) }
        .to have_enqueued_mail(Event::TourApprovalMailer, :required)
        .with(tour, [people(:mitglied)], [people(:admin), people(:familienmitglied), people(:tourenchef)])
    end

    it "sends nothing when receiver_options is none" do
      tour.receiver_options = ["none"]
      expect { tour.update!(state: :review) }.not_to have_enqueued_mail
    end
  end

  describe "translated attributes" do
    [:alternative_route, :additional_info, :price_description].each do |attr|
      it "translates #{attr}" do
        tour.send(:"#{attr}_de=", "ja ja")
        tour.send(:"#{attr}_fr=", "Qui qui")

        I18n.locale = :de
        expect(tour.send(attr)).to eq "ja ja"

        I18n.locale = :fr
        expect(tour.send(attr)).to eq "Qui qui"
      end
    end
  end

  describe "#default_participation_state" do
    let(:application) { Fabricate.build(:event_application) }
    let(:participation) {
      Fabricate.build(:event_participation, event: tour, application: application)
    }

    subject(:state) { tour.default_participation_state(participation) }

    context "without automatic_assignment" do
      before { tour.automatic_assignment = false }

      it "returns unconfirmed if places are available" do
        expect(state).to eq "unconfirmed"
      end

      it "returns applied if course has no places available" do
        tour.maximum_participants = 2
        tour.participant_count = 2
        expect(state).to eq "applied"
      end

      it "returns assigned for participation without application (=leader)" do
        participation.application = nil
        expect(state).to eq "assigned"
      end
    end

    context "with automatic_assignment" do
      before { tour.automatic_assignment = true }

      it "returns applied if places are available" do
        expect(state).to eq "applied"
      end

      it "returns applied if course has no places available" do
        tour.participant_count = 2
        expect(state).to eq "applied"
      end
    end
  end

  describe "#self_approved?" do
    it "is true when all approvals have no freigabe_komitee" do
      tour.approvals.build(freigabe_komitee_id: nil)
      expect(tour).to be_self_approved
    end

    it "is false with no approvals" do
      expect(tour).not_to be_self_approved
    end

    it "is false when any approval has a freigabe_komitee" do
      tour.approvals.build(freigabe_komitee_id: 42)
      expect(tour).not_to be_self_approved
    end
  end

  describe "#reportable?" do
    [:ready, :closed, :canceled].each do |state|
      it "is reportable in state #{state}" do
        tour.state = state

        expect(tour).to be_reportable
      end
    end

    [:draft, :review, :approved, :published].each do |state|
      it "is not reportable in state #{state}" do
        tour.state = state

        expect(tour).not_to be_reportable
      end
    end
  end

  context "paper trails", versioning: true do
    before do
      tour.update_column(:state, :draft)
    end

    it "sets main to event on activity create" do
      expect do
        tour.activities << event_activities(:wandern)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on activity remove" do
      expect do
        tour.activities.destroy_all
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on target_group create" do
      expect do
        tour.target_groups << event_target_groups(:senioren)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on target_group remove" do
      expect do
        tour.target_groups.destroy_all
      end.to change { PaperTrail::Version.count }.by(2) # tour fixture had two target_groups

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on technical_requirement create" do
      expect do
        tour.technical_requirements << event_technical_requirements(:singletrail)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on technical_requirement remove" do
      expect do
        tour.technical_requirements.destroy_all
      end.to change { PaperTrail::Version.count }.by(2) # tour fixture had two technical_requirements

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on trait create" do
      expect do
        tour.traits << event_traits(:training)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on trait remove" do
      expect do
        tour.traits.destroy_all
      end.to change { PaperTrail::Version.count }.by(2) # tour fixture had two traits

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("removed")
      expect(version.main).to eq(tour)
    end
  end

  def enqueued_job_for(job_class, receiver_option)
    Delayed::Job.where("handler LIKE '%#{job_class}%' AND handler LIKE '%#{receiver_option}%'")
  end
end
