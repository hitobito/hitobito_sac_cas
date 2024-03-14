# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe CostCommon do

  shared_examples 'cost common' do
    subject(:model) { described_class.new }
    let(:fabricator) { described_class.model_name.singular.to_s }

    describe "::validations" do
      it "validates presence of label" do
        expect(model).not_to be_valid
        expect(model).to have(1).error_on(:code)
        expect(model).to have(1).error_on(:label)
      end

      it "is valid with code and  label set" do
        model.code = "bar"
        model.label = "foo"
        expect(model).to be_valid
      end

      it "validates uniqueness of code" do
        Fabricate(fabricator, code: 1)
        model = Fabricate.build(fabricator, code: 1)
        expect(model).not_to be_valid
        expect(model).to have(1).error_on(:code)
      end
    end

    describe "::list" do
      it "sorts by code string value" do
        Fabricate(fabricator, code: "test1")
        Fabricate(fabricator, code: "test2")
        Fabricate(fabricator, code: "test11")
        expect(described_class.list.pluck(:code)).to eq %w[test1 test11 test2]
      end
    end

    it "#label uses value from translation" do
      Settings.application.languages.keys.each do |lang|
        I18n.with_locale(lang) { model.label = lang.to_s }
      end
      I18n.with_locale(:de) { expect(model.label).to eq "de" }
      I18n.with_locale(:fr) { expect(model.label).to eq "fr" }
      I18n.with_locale(:it) { expect(model.label).to eq "it" }
      I18n.with_locale(:en) { expect(model.label).to eq "en" }
    end

    it "#to_s joins code with label" do
      model.code = "10"
      model.label = "dummy"
      expect(model.to_s).to eq "10 - dummy"
    end
  end

  describe CostUnit do
    it_behaves_like 'cost common'
  end

  describe CostUnit do
    it_behaves_like 'cost common'
  end
end
