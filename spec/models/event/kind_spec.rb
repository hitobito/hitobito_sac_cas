# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
# == Schema Information
#
# Table name: event_kinds
#
#  id                     :integer          not null, primary key
#  accommodation          :string(255)      default("no_overnight"), not null
#  application_conditions :text(65535)
#  deleted_at             :datetime
#  general_information    :text(65535)
#  kurs_id_fiver          :string(255)
#  maximum_participants   :integer
#  minimum_age            :integer
#  minimum_participants   :integer
#  reserve_accommodation  :boolean          default(TRUE), not null
#  season                 :string(255)
#  short_name             :string(255)
#  training_days          :decimal(5, 2)
#  vereinbarungs_id_fiver :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  cost_center_id         :bigint           not null
#  cost_unit_id           :bigint           not null
#  kind_category_id       :integer
#  level_id               :bigint           not null
#
# Indexes
#
#  index_event_kinds_on_cost_center_id  (cost_center_id)
#  index_event_kinds_on_cost_unit_id    (cost_unit_id)
#  index_event_kinds_on_level_id        (level_id)
#

require "spec_helper"

describe Event::Kind do
  describe "::validations" do
    subject(:kind) { Fabricate.build(:sac_event_kind) }

    it "is valid as builded by fabricator" do
      expect(kind).to be_valid
      expect(kind.level).to eq event_levels(:ek)
    end

    it "validates presence of short_name" do
      kind.short_name = nil
      expect(kind).not_to be_valid
      expect(kind.errors[:short_name]).to eq ["muss ausgefüllt werden"]
    end

    it "validates presence of category" do
      kind.kind_category = nil
      expect(kind).not_to be_valid
      expect(kind.errors[:kind_category]).to eq ["muss ausgefüllt werden"]
    end

    it "validates presence of cost_center" do
      kind.cost_center_id = nil
      expect(kind).not_to be_valid
      expect(kind.errors[:cost_center_id]).to eq ["muss ausgefüllt werden"]
    end

    it "validates presence of cost_unit" do
      kind.cost_unit_id = nil
      expect(kind).not_to be_valid
      expect(kind.errors[:cost_unit_id]).to eq ["muss ausgefüllt werden"]
    end

    it "validates that maximum age is greater than minimum age" do
      kind.minimum_age = 2
      kind.maximum_age = 1
      expect(kind).not_to be_valid
      expect(kind.errors[:maximum_age]).to eq ["muss grösser oder gleich 2 sein"]
    end
  end

  describe "#push_down_inherited_attributes!" do
    let(:course) { events(:application_closed) }
    let(:kind) { event_kinds(:ski_course) }
    let(:kind_attrs) {
      {
        application_conditions: "test",
        minimum_age: 1,
        maximum_age: 2,
        ideal_class_size: 1,
        maximum_class_size: 2,
        minimum_participants: 2,
        maximum_participants: 3,
        training_days: 4,
        season: "winter",
        accommodation: "hut",
        reserve_accommodation: false,
        cost_center_id: 1,
        cost_unit_id: 1
      }
    }

    before do
      kind.attributes = kind_attrs
      kind.save!
    end

    def read_course_attrs
      course.reload.attributes.symbolize_keys.slice(*kind_attrs.keys)
    end

    def with_locales(locales = %w[de fr])
      locales.each { |l| I18n.with_locale(l) { yield(l) } }
    end

    it "updates course attributes" do
      expect do
        kind.push_down_inherited_attributes!
      end.to change { read_course_attrs }.to(kind_attrs)
    end

    it "updates translated application_conditions column" do
      with_locales do |l|
        kind.label = l
        kind.application_conditions = l
      end
      kind.save!
      expect { kind.push_down_inherited_attributes! }.to change { course.translations.count }.by(1)
      I18n.with_locale("de") { expect(course.application_conditions).to eq "de" }
      I18n.with_locale("fr") { expect(course.application_conditions).to eq "fr" }
    end

    it "updates translated description with general_information column" do
      with_locales do |l|
        kind.label = l
        kind.general_information = l
      end
      kind.save!
      expect { kind.push_down_inherited_attributes! }.to change { course.translations.count }.by(1)
      I18n.with_locale("de") { expect(course.description).to eq "de" }
      I18n.with_locale("fr") { expect(course.description).to eq "fr" }
    end

    it "overrides existing values with blanks" do
      kind.update!(minimum_age: nil)
      course.update!(minimum_age: 12)

      expect do
        kind.push_down_inherited_attributes!
      end.to change { course.reload.minimum_age }.from(12).to(nil)
    end

    it "noops when course is not associated with kind" do
      course.update_columns(kind_id: -1)
      expect { kind.push_down_inherited_attributes! }.not_to change { read_course_attrs }
    end

    describe "ignored states" do
      %w[closed canceled].each do |ignored|
        before { course.update_columns(state: ignored) }

        it "noops for course in #{ignored} state" do
          expect do
            kind.push_down_inherited_attributes!
          end.not_to change { read_course_attrs }
        end

        it "updates translated application_conditions column" do
          with_locales do |l|
            kind.label = l
            kind.application_conditions = l
          end
          kind.save!
          expect { kind.push_down_inherited_attributes! }.not_to change {
            course.translations.count
          }
          I18n.with_locale("de") { expect(course.application_conditions).to be_blank }
          I18n.with_locale("fr") { expect(course.application_conditions).to be_blank }
        end
      end
    end
  end

  describe "#push_down_inherited_attribute!" do
    let(:course) { events(:application_closed) }
    let(:kind) { event_kinds(:ski_course) }
    let(:kind_attrs) {
      {
        application_conditions: "test",
        minimum_age: 1,
        maximum_age: 2,
        ideal_class_size: 1,
        maximum_class_size: 2,
        minimum_participants: 2,
        maximum_participants: 3,
        training_days: 4,
        season: "summer",
        accommodation: "hut",
        reserve_accommodation: false,
        cost_center_id: 1,
        cost_unit_id: 1
      }
    }

    before do
      kind.update!(kind_attrs)
    end

    def read_course_attrs
      course.reload.attributes.symbolize_keys.slice(*kind_attrs.keys)
    end

    def with_locales(locales = %w[de fr])
      locales.each { |l| I18n.with_locale(l) { yield(l) } }
    end

    it "updates course integer attribute" do
      expect do
        kind.push_down_inherited_attribute!("maximum_participants")
      end.to change { course.reload.maximum_participants }.to(kind_attrs[:maximum_participants])
    end

    it "updates course belongs_to attribute" do
      expect do
        kind.push_down_inherited_attribute!("cost_center_id")
      end.to change { course.reload.cost_center_id }.to(kind_attrs[:cost_center_id])
    end

    it "updates course boolean attribute" do
      expect do
        kind.push_down_inherited_attribute!("reserve_accommodation")
      end.to change { course.reload.reserve_accommodation }.to(kind_attrs[:reserve_accommodation])
    end

    it "updates course enum attribute" do
      expect do
        kind.push_down_inherited_attribute!("season")
      end.to change { course.reload.season }.to(kind_attrs[:season])
    end

    it "updates translated application_conditions column" do
      with_locales do |l|
        kind.label = l
        kind.application_conditions = l
      end
      kind.save!
      expect { kind.push_down_inherited_attribute!("application_conditions") }.to change {
        course.translations.count
      }.by(1)
      I18n.with_locale("de") { expect(course.application_conditions).to eq "de" }
      I18n.with_locale("fr") { expect(course.application_conditions).to eq "fr" }
    end

    it "updates translated application_conditions column with blanks" do
      with_locales do |l|
        kind.label = l
        kind.application_conditions = nil
      end
      kind.save!
      expect { kind.push_down_inherited_attribute!("application_conditions") }.to change {
        course.translations.count
      }.by(1)
      I18n.with_locale("de") { expect(course.application_conditions).to be_nil }
      I18n.with_locale("fr") { expect(course.application_conditions).to be_nil }
    end

    it "updates translated general_information/description column" do
      with_locales do |l|
        kind.label = l
        kind.general_information = l
      end
      kind.save!
      expect { kind.push_down_inherited_attribute!("general_information") }.to change {
        course.translations.count
      }.by(1)
      I18n.with_locale("de") { expect(course.description).to eq "de" }
      I18n.with_locale("fr") { expect(course.description).to eq "fr" }
    end

    it "overrides existing values with blanks" do
      kind.update!(minimum_age: nil)
      course.update!(minimum_age: 12)

      expect do
        kind.push_down_inherited_attribute!("minimum_age")
      end.to change { course.reload.minimum_age }.from(12).to(nil)
    end
  end
end
