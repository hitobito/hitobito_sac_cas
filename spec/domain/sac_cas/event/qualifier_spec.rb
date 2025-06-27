require "spec_helper"

describe Event::Qualifier do
  let(:event_kind) { event_kinds(:ski_course) }
  let(:ski_leader) { qualification_kinds(:ski_leader) }
  let(:course) do
    event = Fabricate(:course, kind: event_kind)
    event.dates.create!(start_at: quali_date, finish_at: quali_date)
    event
  end

  let(:participation) do
    participation = Fabricate(:event_participation, event: course, person: participant)
    Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
    participation.reload
  end

  let(:participant) { Fabricate(:person) }
  let(:quali_date) { Date.new(2012, 10, 20) }

  def create_qualification(person, date, kind)
    Fabricate(:qualification,
      person: person,
      qualification_kind: qualification_kinds(kind),
      start_at: date,
      qualified_at: date)
  end

  def obtained_qualification(person, origin, kind)
    person.qualifications.find_by(origin: origin, qualification_kind: kind)
  end

  def create_course_participation(start_at:, training_days: nil, actual_days: nil)
    course = Fabricate.build(
      :course,
      name: "Kurs #{start_at.year}",
      number: "01-#{start_at.year}",
      kind: event_kind,
      training_days: training_days
    )
    course.dates.build(start_at: start_at - (training_days - 1).days, finish_at: start_at)
    course.save!
    Fabricate(
      :event_participation,
      event: course,
      person: participant,
      qualified: true,
      actual_days: actual_days
    )
  end

  def create_external_training(start_at:, training_days: nil, actual_days: nil)
    ExternalTraining.create!(
      person: participant,
      name: "Training #{start_at.year}",
      event_kind: event_kind,
      start_at: start_at,
      finish_at: start_at + (training_days - 1).days,
      training_days: training_days
    )
  end

  context "prolongations conditional to required training days, including external trainings" do
    let!(:initial_qualification) { create_qualification(participant, Date.new(2010, 3, 10), :ski_leader) }

    it "noops if participation does not have required actual days" do
      participation = create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 2, actual_days: 1.5)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "prolongs if participation has required trainings days" do
      participation = create_course_participation(start_at: Date.new(2012, 6, 1), training_days: 2)

      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)
      qualification = obtained_qualification(participant, participation.event.name, ski_leader)
      expect(qualification.start_at).to eq Date.new(2012, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2012, 6, 1)
    end

    it "noops if current and previous courses combined do not have required training days" do
      create_external_training(start_at: Date.new(2011, 6, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2012, 4, 1), training_days: 0.5)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "noops if current participation does not have enough actual days" do
      create_external_training(start_at: Date.new(2011, 6, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2012, 4, 1), training_days: 1, actual_days: 0.5)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "noops if previous participation does not have enough actual days" do
      create_course_participation(start_at: Date.new(2011, 6, 1), training_days: 1, actual_days: 0.5)
      participation = create_course_participation(start_at: Date.new(2012, 4, 1), training_days: 1)
      expect { Event::Qualifier.for(participation).issue }.not_to change { participant.qualifications.count }
    end

    it "prolongs if current and previous courses combined have required trainings days" do
      create_external_training(start_at: Date.new(2011, 6, 1), training_days: 1)
      participation = create_course_participation(start_at: Date.new(2012, 4, 1), training_days: 1)
      expect { Event::Qualifier.for(participation).issue }.to change { participant.qualifications.count }.by(1)

      qualification = obtained_qualification(participant, participation.event.name, ski_leader)
      expect(qualification.start_at).to eq Date.new(2011, 6, 1)
      expect(qualification.qualified_at).to eq Date.new(2012, 4, 1)
    end
  end
end
