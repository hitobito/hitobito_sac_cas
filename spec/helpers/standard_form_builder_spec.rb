# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe StandardFormBuilder do
  let(:attrs) { {} }
  let(:wizard) { instance_double("Wizards::Base", current_user: nil) }
  let(:entry) { TestModel.new(wizard, **attrs) }
  let(:form) { StandardFormBuilder.new(:entry, entry, self, {}) }

  include UtilityHelper

  describe "required?" do
    it "does not require address if street and housennumber have no validation" do
      stub_const("TestModel", Class.new(Wizards::Step) do
        attribute :street, type: :string
        attribute :housenumber, type: :string
      end)
      expect(form.required?(:address)).to eq false
    end

    it "does require address if street and housennumber have a presence validation" do
      stub_const("TestModel", Class.new(Wizards::Step) do
        attribute :street, type: :string
        attribute :housenumber, type: :string

        validates :street, :housenumber, presence: true
      end)
      expect(form.required?(:address)).to eq true
    end
  end
end
