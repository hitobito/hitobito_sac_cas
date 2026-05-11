# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
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

    describe "disciplines" do
      let(:new_valid_value) { [event_disciplines(:indoorklettern)] }

      it_behaves_like "presence validation for draft attributes", attribute: :disciplines, association: true
      it_behaves_like "readonly for draft attributes", attribute: :disciplines
    end

    describe "target_groups" do
      let(:new_valid_value) { [event_target_groups(:familien)] }

      it_behaves_like "presence validation for draft attributes", attribute: :target_groups, association: true
      it_behaves_like "readonly for draft attributes", attribute: :target_groups
    end

    describe "technical_requirements" do
      let(:new_valid_value) { [event_technical_requirements(:klettern_9a)] }

      it_behaves_like "presence validation for draft attributes", attribute: :technical_requirements, association: true
      it_behaves_like "readonly for draft attributes", attribute: :technical_requirements
    end

    describe "price_regular" do
      it "may be empty in state approved" do
        tour.state = :approved
        tour.price_regular = nil
        expect(tour).to be_valid
      end

      it "may be empty in state canceled" do
        tour.update!(state: :approved)
        tour.state = :canceled
        tour.price_regular = nil
        expect(tour).to be_valid
      end

      it "must be present in state published" do
        tour.state = :published
        tour.price_regular = nil
        expect(tour).not_to be_valid
        expect(tour.errors[:price_regular]).to eq ["muss ausgefüllt werden"]
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

      it "enqueues job for interested_section_people with publication key" do
        tour.receiver_options = ["interested_section_people"]

        expect(tour).to receive(:enqueue_email_job).with("interested_section_people", :publication)
          .once
          .and_call_original
        expect { tour.update!(state: :published) }
          .to change(
            Delayed::Job.where("handler LIKE '%Event::Tour::InterestedSectionPeopleEmailDispatchJob%'"), :count
          ).by(1)
          .and change(
            Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
          ).by(1)
      end

      it "enqueues job for assigned_freigabe_komitees with publication key" do
        tour.receiver_options = ["assigned_freigabe_komitees"]

        expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :publication)
          .once
          .and_call_original
        expect { tour.update!(state: :published) }
          .to change(
            Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
          ).by(1)
          .and change(
            Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
          ).by(1)
      end

      it "enqueues job for leaders with publication key" do
        tour.receiver_options = ["leaders"]

        expect(tour).to receive(:enqueue_email_job).with("leaders", :publication).once.and_call_original
        expect { tour.update!(state: :published) }
          .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
          .and change(
            Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
          ).by(1)
      end

      context "subito tour" do
        before do
          tour.update_column(:subito, true)
        end

        it "enqueues job for interested_section_people with publication_subito key" do
          tour.receiver_options = ["interested_section_people"]

          expect(tour).to receive(:enqueue_email_job).with("interested_section_people", :publication_subito)
            .once
            .and_call_original
          expect { tour.update!(state: :published) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::InterestedSectionPeopleEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with publication_subito key" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :publication_subito)
            .once
            .and_call_original
          expect { tour.update!(state: :published) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with publication_subito key" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :publication_subito).once.and_call_original
          expect { tour.update!(state: :published) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
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

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :back_to_published)
            .once
            .and_call_original
          expect { tour.update!(state: :published) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with back_to_published key" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :back_to_published).once.and_call_original
          expect { tour.update!(state: :published) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
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
        expect(tour).to receive(:enqueue_email_job).with("participants_confirmed", :participation_summon)
          .once
          .and_call_original
        expect { tour.update!(state: :ready) }
          .to change(Delayed::Job.where("handler LIKE '%Event::Tour::ParticipantsEmailDispatchJob%'"), :count).by(1)
          .and change(
            Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
          ).by(1)
      end

      it "enqueues job for participants_unconfirmed with participation_reject key" do
        tour.receiver_options = ["participants_unconfirmed"]

        expect(tour).to receive(:participant_states)
          .once
          .and_return(["unconfirmed", "applied"])
        expect(tour).to receive(:enqueue_email_job).with("participants_unconfirmed", :participation_reject)
          .once
          .and_call_original
        expect { tour.update!(state: :ready) }
          .to change(Delayed::Job.where("handler LIKE '%Event::Tour::ParticipantsEmailDispatchJob%'"), :count).by(1)
          .and change(
            Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
          ).by(0)
      end

      it "enqueues job for leaders with participation_summon key" do
        tour.receiver_options = ["leaders"]

        expect(tour).to receive(:enqueue_email_job).with("leaders", :participation_summon)
          .once
          .and_call_original
        expect { tour.update!(state: :ready) }
          .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
          .and change(
            Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
          ).by(1)
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

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :back_to_ready)
            .once
            .and_call_original
          expect { tour.update!(state: :ready) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :back_to_ready)
            .once
            .and_call_original
          expect { tour.update!(state: :ready) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
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
      expect(tour).to receive(:enqueue_email_job).with("participants_participated", :closing)
        .once
        .and_call_original
      expect { tour.update!(state: :closed) }
        .to change(Delayed::Job.where("handler LIKE '%Event::Tour::ParticipantsEmailDispatchJob%'"), :count).by(1)
        .and change(
          Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
        ).by(1)
    end

    it "enqueues job for leaders with closing key" do
      tour.receiver_options = ["leaders"]

      expect(tour).to receive(:enqueue_email_job).with("leaders", :closing)
        .once
        .and_call_original
      expect { tour.update!(state: :closed) }
        .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
        .and change(
          Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
        ).by(1)
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
          expect(tour).to receive(:enqueue_email_job).with("participants", :canceled_weather)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :weather) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::ParticipantsEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with weather mail if canceled_reason is weather" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :canceled_weather)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :weather) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with weather mail if canceled_reason is weather" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :canceled_weather)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :weather) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for participants with no leader mail if canceled_reason is no_leader" do
          tour.receiver_options = ["participants"]

          expect(tour).to receive(:participant_states)
            .once
            .and_return(["unconfirmed", "applied", "assigned", "summoned"])
          expect(tour).to receive(:enqueue_email_job).with("participants", :canceled_no_leader)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :no_leader) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::ParticipantsEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with no leader mail if canceled_reason is no_leader" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :canceled_no_leader)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :no_leader) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with no leader mail if canceled_reason is no_leader" do
          tour.receiver_options = ["leaders"]

          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :canceled_no_leader)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :no_leader) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for participants with minimum participants mail if canceled_reason is minimum_participants" do
          tour.receiver_options = ["participants"]

          expect(tour).to receive(:participant_states)
            .once
            .and_return(["unconfirmed", "applied", "assigned", "summoned"])
          expect(tour).to receive(:enqueue_email_job).with("participants", :canceled_minimum_participants)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :minimum_participants) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::ParticipantsEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for assigned_freigabe_komitees with minimum participants mail if minimum_participants" do
          tour.receiver_options = ["assigned_freigabe_komitees"]

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :canceled_minimum_participants)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :minimum_participants) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with minimum participants mail if canceled_reason is minimum_participants" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :canceled_minimum_participants)
            .once
            .and_call_original
          expect { tour.update!(state: :canceled, canceled_reason: :minimum_participants) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
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

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :back_to_draft)
            .once
            .and_call_original
          expect { tour.update!(state: :draft) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with back_to_draft key" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :back_to_draft)
            .once
            .and_call_original
          expect { tour.update!(state: :draft) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end
      end
    end
  end

  describe "when state changes to approved" do
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

          expect(tour).to receive(:enqueue_email_job).with("assigned_freigabe_komitees", :back_to_approved)
            .once
            .and_call_original
          expect { tour.update!(state: :approved) }
            .to change(
              Delayed::Job.where("handler LIKE '%Event::Tour::AssignedFreigabeKomiteesEmailDispatchJob%'"), :count
            ).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end

        it "enqueues job for leaders with back_to_approved key" do
          tour.receiver_options = ["leaders"]

          expect(tour).to receive(:enqueue_email_job).with("leaders", :back_to_approved)
            .once
            .and_call_original
          expect { tour.update!(state: :approved) }
            .to change(Delayed::Job.where("handler LIKE '%Event::Tour::LeadersEmailDispatchJob%'"), :count).by(1)
            .and change(
              Delayed::Job.where("handler LIKE '%Event::Tour::EssentialPeopleEmailDispatchJob%'"), :count
            ).by(1)
        end
      end
    end

    [:draft, :review].each do |from_state|
      context "from #{from_state}" do
        before do
          tour.update_column(:state, from_state)
        end

        it "does not send email" do
          tour.receiver_options = ["assigned_freigabe_komitees", "leaders"]

          expect { tour.update!(state: :approved) }.not_to change(Delayed::Job, :count)
        end
      end
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

  context "paper trails", versioning: true do
    before do
      tour.update_column(:state, :draft)
    end

    it "sets main to event on discipline create" do
      expect do
        tour.disciplines << event_disciplines(:wandern)
      end.to change { PaperTrail::Version.count }.by(1)

      version = PaperTrail::Version.order(:created_at, :id).last
      expect(version.event).to eq("create")
      expect(version.main).to eq(tour)
    end

    it "sets main to event on discipline remove" do
      expect do
        tour.disciplines.destroy_all
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
end
