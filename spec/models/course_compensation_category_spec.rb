# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe CourseCompensationCategory do
  subject(:model) { described_class.new }

  it "#name_leader uses values from translation" do
    Settings.application.languages.keys.each do |lang|
      I18n.with_locale(lang) { model.name_leader = lang.to_s }
    end
    I18n.with_locale(:de) { expect(model.name_leader).to eq "de" }
    I18n.with_locale(:fr) { expect(model.name_leader).to eq "fr" }
    I18n.with_locale(:it) { expect(model.name_leader).to eq "it" }
    I18n.with_locale(:en) { expect(model.name_leader).to eq "en" }
  end

  it "#name_assistant_leader uses values from translation" do
    Settings.application.languages.keys.each do |lang|
      I18n.with_locale(lang) { model.name_assistant_leader = lang.to_s }
    end
    I18n.with_locale(:de) { expect(model.name_assistant_leader).to eq "de" }
    I18n.with_locale(:fr) { expect(model.name_assistant_leader).to eq "fr" }
    I18n.with_locale(:it) { expect(model.name_assistant_leader).to eq "it" }
    I18n.with_locale(:en) { expect(model.name_assistant_leader).to eq "en" }
  end

  it "#to_s shows short name and translated kind" do
    model.short_name = "dummy"
    model.kind = :flat
    expect(model.to_s).to eq "dummy (Pauschale)"
  end

  context "destroy" do
    let!(:course_compensation_category) { Fabricate(:course_compensation_category) }
    let!(:course_compensation_rate) { Fabricate(:course_compensation_rate, course_compensation_category: course_compensation_category) }

    it "is prevented if associated course_compensation_rates exist" do
      expect { course_compensation_category.destroy }.not_to change { CourseCompensationCategory.count }
      expect(course_compensation_category.errors.full_messages[0]).to eq "Datensatz kann nicht gelöscht werden, " \
        "da abhängige Vergütungsansätze existieren."
    end

    it "succeeds if no associated course_compensation_rates exists" do
      course_compensation_rate.destroy!
      expect { course_compensation_category.destroy }.to change { CourseCompensationCategory.count }.by(-1)
    end
  end
end
