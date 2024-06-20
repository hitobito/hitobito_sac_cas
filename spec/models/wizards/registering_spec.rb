# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Wizards::Registering do
  before do
    stub_const('Step1', Class.new(Wizards::Step))
    stub_const('Step2', Class.new(Wizards::Step))

    stub_const('RegisteringWizard', Class.new(Wizards::Base) do
      include Wizards::Registering

      self.steps = [Step1, Step2]
    end)
  end

  let(:opts) { { current_step: 1 } }
  subject(:wizard) { RegisteringWizard.new(**opts) }

  it 'is a personal wizard' do
    expect(wizard).to be_a(Wizards::Personal)
  end

  it 'has group attribute' do
    expect(wizard.attribute_names).to include('group')
  end

  it "validates presence of group on last step" do
    opts[:current_step] = 1
    wizard.validate
    expect(wizard.errors[:group]).to include("muss ausgefüllt werden")
  end

  it "does not validate presence of group when not on last step" do
    opts[:current_step] = 0
    wizard.validate
    expect(wizard.errors[:group]).to be_empty
  end

  describe '#no_self_service?' do
    it 'returns true if group has a child of type Group::SektionsNeuanmeldungenSektion' do
      wizard.group = instance_double(Group, children: [Group::SektionsNeuanmeldungenSektion.new])
      expect(wizard).to be_no_self_service
    end

    it 'returns false if group has no child of type Group::SektionsNeuanmeldungenSektion' do
      wizard.group = instance_double(Group, children: [Group::SektionsNeuanmeldungenNv.new])
      expect(wizard).not_to be_no_self_service
    end
  end
end
