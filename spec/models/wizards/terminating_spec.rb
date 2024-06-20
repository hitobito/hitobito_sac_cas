# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Wizards::Terminating do
  before do
    stub_const('TerminatingWizard', Class.new(Wizards::Base) do
      include Wizards::Terminating
    end)
  end

  let(:opts) { { current_step: 0 } }
  subject(:wizard) { TerminatingWizard.new(**opts) }

  it 'is a personal wizard' do
    expect(wizard).to be_a(Wizards::Personal)
  end

  it 'has role attribute' do
    expect(wizard.attribute_names).to include('role')
  end

  it "validates presence of role" do
    expect(wizard).not_to be_valid
    expect(wizard.errors[:role]).to include("muss ausgefüllt werden")
  end

  describe '#no_self_service?' do
    before { allow(wizard).to receive(:affected_roles).and_return(roles(:mitglied, :abonnent_alpen)) }

    it 'returns true if any role section has termination by section only' do
      groups(:bluemlisalp).update!(mitglied_termination_by_section_only: true)
      expect(wizard.no_self_service?).to be true
    end

    it 'returns false if no role section has termination by section only' do
      # check assumed precondition
      expect(groups(:bluemlisalp).mitglied_termination_by_section_only).to be false
      expect(wizard.no_self_service?).to be false
    end
  end
end
