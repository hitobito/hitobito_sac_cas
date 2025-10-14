# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe ExternalTrainings::Qualifier do
  let(:role) { "participant" }
  let(:mitglied) { people(:mitglied) }
  let(:ski_leader) { qualification_kinds(:ski_leader) }
  let(:ski_course) { event_kinds(:ski_course) }
  let(:today) { Date.new(2024, 3, 26) }
  let(:start_dates) { Qualification.order(:start_at).pluck(:start_at) }
  let(:snowboard_leader) { qualification_kinds(:snowboard_leader) }
  let(:snowboard_qualis) { mitglied.qualifications.where(qualification_kind: snowboard_leader) }

  describe "issue" do
    it "noops when no qualification exists" do
      training = create_external_training(start_at: today)
      expect { issue(training) }.not_to change { Qualification.count }
    end

    it "noops when qualification is too old" do
      create_qualification(start_at: today - 7.years)
      training = create_external_training(start_at: today)
      expect { issue(training) }.not_to change { Qualification.count }
    end

    # rubocop:todo Layout/LineLength
    it "creates a new qualification when existing qualification is from last day of prolongation period" do
      # rubocop:enable Layout/LineLength
      create_qualification(start_at: today - 6.years)
      training = create_external_training(start_at: today)
      expect { issue(training) }.to change { Qualification.count }.by(1)
    end

    it "noops when training does not have enough days" do
      create_qualification(start_at: today - 2.years)
      training = create_external_training(start_at: today, training_days: 1)
      expect { issue(training) }.not_to change { Qualification.count }
    end

    it "counts required days from both courses and trainings" do
      create_qualification(start_at: today - 2.years)
      create_course_participation(start_at: today, qualified: true, training_days: 1)
      training = create_external_training(start_at: today, training_days: 1)
      expect { issue(training) }.to change { Qualification.count }
    end

    it "noops when earlier participation does not have enough actual days" do
      create_qualification(start_at: today - 2.years)
      create_course_participation(start_at: today, qualified: true, training_days: 1,
        actual_days: 0.5)
      training = create_external_training(start_at: today, training_days: 1)
      expect { issue(training) }.not_to change { Qualification.count }
    end

    context "with existing qualifications" do
      before do
        create_qualification(start_at: today - 4.years)
        create_qualification(start_at: today - (2.years - 1.month))
        create_qualification(start_at: today - 11.months)
        @training = create_external_training(start_at: today - 2.years, training_days: 2)
      end

      it "inserts new and deletes both obsolete qualifications" do
        expect { issue(@training) }.to change { Qualification.count }.by(-1)
        expect(start_dates).to eq [
          today - 4.years,
          today - 2.years
        ]
      end

      it "inserts new, keeps former support and deletes later obsolete qualification" do
        create_external_training(start_at: today - 2.years + 1.month, training_days: 2)

        expect { issue(@training) }.not_to change { Qualification.count }
        expect(start_dates).to eq [
          today - 4.years,
          today - 2.years,
          today - (2.years - 1.month)
        ]
      end

      it "inserts new, deletes former obsolete and keps later supported qualification" do
        later = create_external_training(start_at: today - 11.months, training_days: 2)

        expect { issue(@training) }.not_to change { Qualification.count }
        expect(start_dates).to eq [
          today - 4.years,
          today - 2.years,
          today - 11.months
        ]
        expect(Qualification.order(:start_at).pluck(:origin)).to eq [
          nil,
          @training.to_s,
          later.to_s
        ]
      end

      it "inserts new, keeps both supported qualifications" do
        create_external_training(start_at: today - 2.years + 1.month, training_days: 2)
        create_course_participation(start_at: today - 1.year + 1.month, training_days: 2)

        expect { issue(@training) }.to change { Qualification.count }.by(1)
        expect(start_dates).to eq [
          today - 4.years,
          today - 2.years,
          today - (2.years - 1.month),
          today - 11.months
        ]
      end
    end

    context "mulitple qualification kinds" do
      before do
        create_qualification(start_at: today - 11.months)
        create_qualification(start_at: today - 18.months, kind: snowboard_leader)
        @snow_pro = create_event_kind_qualification_kind(ski_course, snowboard_leader)
      end

      it "creates a new snowboard leader when issuing after quali date" do
        training = create_external_training(start_at: today - 5.months, training_days: 0)
        expect { issue(training) }.to change { Qualification.count }.by(1)
        expect(start_dates).to eq [
          today - 18.months,
          today - 11.months,
          today - 5.months
        ]
        expect(snowboard_qualis).to have(2).items
      end

      # rubocop:todo Layout/LineLength
      it "creates a new snowboard leader when issuing after quali date if category is qualification" do
        # rubocop:enable Layout/LineLength
        @snow_pro.update!(category: :qualification)

        training = create_external_training(start_at: today - 5.months, training_days: 0)
        expect { issue(training) }.to change { Qualification.count }.by(1)
        expect(start_dates).to eq [
          today - 18.months,
          today - 11.months,
          today - 5.months
        ]
        expect(snowboard_qualis).to have(2).items
      end

      it "deletes obsolete ski leader when issuing after snowboard but before ski quali date" do
        training = create_external_training(start_at: today - 15.months, training_days: 1)
        expect { issue(training) }.not_to change { Qualification.count }
        expect(start_dates).to eq [
          today - 18.months,
          today - 15.months
        ]
        expect(snowboard_qualis).to have(2).items
      end

      # rubocop:todo Layout/LineLength
      it "deletes all obsolete qualifications and hence has nothing to prolong when issuing before snowboard" do
        # rubocop:enable Layout/LineLength
        training = create_external_training(start_at: today - 20.months, training_days: 1)
        expect { issue(training) }.to change { Qualification.count }.by(-2)
        expect(start_dates).to eq []
      end

      # rubocop:todo Layout/LineLength
      it "deletes all obsolete qualifications and keeps snowboard if not associated with event_kind" do
        # rubocop:enable Layout/LineLength
        @snow_pro.destroy!
        training = create_external_training(start_at: today - 20.months, training_days: 1)
        expect { issue(training) }.to change { Qualification.count }.by(-1)
        expect(start_dates).to eq [today - 18.months]
        expect(snowboard_qualis).to have(1).items
      end

      it "keeps ski and snowboard when issuing after snowboard and supporting event exist" do
        training = create_external_training(start_at: today - 5.months, training_days: 0)
        create_external_training(start_at: today - 11.months, training_days: 2)
        expect { issue(training) }.to change { Qualification.count }.by(1)
        expect(mitglied.qualifications.where(qualification_kind: snowboard_leader)).to have(2).items
      end
    end

    def issue(training)
      described_class.new(mitglied, training, role).issue
    end
  end

  describe "revoke" do
    it "noops when no qualification exists" do
      training = create_external_training(start_at: today)
      expect { revoke(training) }.not_to change { Qualification.count }
    end

    it "deletes later training qualification and keeps other" do
      create_qualification(start_at: today - 1.year)
      create_qualification(start_at: today)

      training = create_external_training(start_at: today, qualification: true)
      expect { revoke(training) }.to change { Qualification.count }.by(-1)
      expect(start_dates).to eq [today - 1.year]
    end

    it "deletes earlier training qualification and removes other as nothing to prolong" do
      create_qualification(start_at: today - 1.year)
      create_qualification(start_at: today - 10.months)

      training = create_external_training(start_at: today - 1.year)
      expect { revoke(training) }.to change { Qualification.count }.by(-2)
    end

    context "with multiple existing qualifications" do
      before do
        create_qualification(start_at: today - 2.years)
        create_qualification(start_at: today - 1.year)
        create_qualification(start_at: today - 10.months)

        @training = create_external_training(start_at: today - 1.year)
      end

      it "deletes earlier training qualification and removes other as no supporting event exists" do
        expect { revoke(@training) }.to change { Qualification.count }.by(-2)
        expect(start_dates).to eq [today - 2.years]
      end

      # rubocop:todo Layout/LineLength
      it "deletes earlier training qualification and keeps other when support quali and event exists" do
        # rubocop:enable Layout/LineLength
        create_external_training(start_at: today - 10.months)

        expect { revoke(@training) }.to change { Qualification.count }.by(-1)
        expect(start_dates).to eq [today - 2.years, today - 10.months]
      end

      # rubocop:todo Layout/LineLength
      it "deletes earlier training qualification and removes other when event has not enough days" do
        # rubocop:enable Layout/LineLength
        create_external_training(start_at: today - 10.months, training_days: 1)

        @training.update(training_days: 0.5)
        expect { revoke(@training) }.to change { Qualification.count }.by(-2)
        expect(start_dates).to eq [today - 2.years]
      end

      it "deletes earlier training qualification and moves back other when event has enough days" do
        create_external_training(start_at: today - 15.months, training_days: 1)
        create_course_participation(start_at: today - 10.months, training_days: 1)

        @training.update(training_days: 0)
        expect { revoke(@training) }.to change { Qualification.count }.by(-1)
        expect(start_dates).to eq [today - 2.years, today - 15.months]
      end
    end

    context "mulitple qualification kinds" do
      before do
        create_qualification(start_at: today - 2.years)
        create_qualification(start_at: today - 11.months)
        create_qualification(start_at: today - 18.months, kind: snowboard_leader)
        @snow_pro = create_event_kind_qualification_kind(ski_course, snowboard_leader)
      end

      it "deletes later qualification keeping others in place" do
        training = create_external_training(start_at: today - 5.months)
        create_qualification(start_at: today - 5.months)

        expect { revoke(training) }.to change { Qualification.count }.by(-1)
      end

      it "deletes earlier qualification and snowboard if associated with event" do
        training = create_external_training(start_at: today - 20.months)
        create_qualification(start_at: today - 20.months)

        expect { revoke(training) }.to change { Qualification.count }.by(-3)
        expect(snowboard_qualis).to be_empty
      end

      # rubocop:todo Layout/LineLength
      it "deletes earlier qualification and keeps only ski if supporting events exist as snowboard has nothing to prolong" do
        # rubocop:enable Layout/LineLength
        training = create_external_training(start_at: today - 20.months)
        create_qualification(start_at: today - 20.months)

        create_external_training(start_at: today - 11.months)
        create_external_training(start_at: today - 18.months)

        expect { revoke(training) }.to change { Qualification.count }.by(-1)
        expect(start_dates).to eq [today - 2.years, today - 18.months, today - 11.months]
        expect(snowboard_qualis).to be_empty
      end

      it "deletes earlier qualification and keeps both if snowboard qualifies" do
        training = create_external_training(start_at: today - 20.months)
        create_qualification(start_at: today - 20.months)

        create_external_training(start_at: today - 11.months)
        create_external_training(start_at: today - 18.months)
        @snow_pro.update!(category: :qualification)

        expect { revoke(training) }.to change { Qualification.count }.by(1)
        expect(start_dates).to eq [today - 2.years, today - 18.months, today - 18.months,
          today - 11.months, today - 11.months]
        expect(snowboard_qualis).to have(2).item
      end

      # rubocop:todo Layout/LineLength
      it "deletes earlier qualification and keeps snowboard in place if not related with event_kind" do
        # rubocop:enable Layout/LineLength
        training = create_external_training(start_at: today - 20.months)
        create_qualification(start_at: today - 20.months)
        @snow_pro.destroy!

        expect { revoke(training) }.to change { Qualification.count }.by(-2)
        expect(snowboard_qualis).to have(1).item
      end
    end

    def revoke(training)
      described_class.new(mitglied, training, role).revoke
    end
  end

  def create_external_training(start_at:, finish_at: start_at, kind: nil, training_days: 2,
    qualification: false)
    Fabricate(:external_training_skip_issue_qualifications, {
      person: mitglied,
      event_kind: kind || ski_course,
      start_at: start_at,
      finish_at: finish_at,
      training_days: training_days
    })
  end

  def create_event_kind_qualification_kind(event_kind, qualification_kind, category: :prolongation)
    Event::KindQualificationKind.create!(
      event_kind: event_kind,
      qualification_kind: qualification_kind,
      category: category,
      role: role
    )
  end

  def create_course_participation(start_at:, kind: ski_course, training_days: 2, qualified: true,
    actual_days: nil)
    course = Fabricate.build(:sac_course, kind: kind, training_days: training_days)
    course.dates.build(start_at: start_at - (training_days - 1).days, finish_at: start_at)
    course.save!
    Fabricate(:event_participation, event: course, participant: mitglied, qualified: qualified,
      actual_days: actual_days)
  end

  def create_qualification(start_at:, qualified_at: start_at, kind: ski_leader)
    Fabricate(:qualification, qualification_kind: kind, person: mitglied, start_at: start_at,
      qualified_at: qualified_at)
  end
end
