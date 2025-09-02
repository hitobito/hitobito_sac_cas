# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::CourseParticipationInvoice do
  let(:member) { people(:mitglied) }
  let(:course) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course), dates: [
      Event::Date.new(start_at: "01.01.2024", finish_at: "31.01.2024"),
      Event::Date.new(start_at: "01.03.2024", finish_at: "31.03.2024")
    ])
  end
  let(:participation) { Fabricate(:event_participation, event: course, participant: member, price: 20, price_category: :price_regular) }

  subject { described_class.new(participation) }

  context "#invoice?" do
    it "is true when course price is present" do
      expect(subject.invoice?).to be(true)
    end

    it "is false when course price is zero" do
      participation.update!(price: 0)

      expect(subject.invoice?).to be(false)
    end
  end

  context "#position" do
    let(:position) { subject.positions.first }

    it "creates position with correct values" do
      expect(position.name).to eq("Normalpreis - Einstiegskurs")
      expect(position.grouping).to eq("Normalpreis - Einstiegskurs")
      expect(position.amount).to eq(20)
      expect(position.count).to eq(1)
      expect(position.article_number).to eq("49kurs-1")
      expect(position.cost_center).to eq("kurs-1")
      expect(position.cost_unit).to eq("ski-1")
    end

    it "displays j_s price labels for j_s courses" do
      course.kind.kind_category.update_column(:j_s_course, true)
      expect(position.name).to eq "J&S P-Normalpreis - Einstiegskurs"
    end
  end

  context "#additional_user_fields" do
    it "sets additional user fields" do
      additional_user_fields = subject.additional_user_fields

      expect(additional_user_fields[:user_field8]).to eq(course.number)
      expect(additional_user_fields[:user_field9]).to eq("Eventus")
      expect(additional_user_fields[:user_field10]).to eq("01.01.2024 - 31.01.2024, 01.03.2024 - 31.03.2024")
    end
  end

  context "user language" do
    before do
      member.language = "fr"
      I18n.with_locale("fr") do
        course.update!(name: "Evenement")
        course.kind.level.update!(label: "Cours de base")
      end
    end

    it "is used for labels" do
      position = subject.positions.first
      expect(position.name).to eq("Prix normal - Cours de base")

      additional_user_fields = subject.additional_user_fields
      expect(additional_user_fields[:user_field8]).to eq(course.number)
      expect(additional_user_fields[:user_field9]).to eq("Evenement")
    end
  end
end
