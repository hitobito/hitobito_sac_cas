# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe SacCas::Event::ParticipationDecorator do
  let(:admin) { people(:admin) }
  let(:participation) { Fabricate.build(:event_participation, participant: admin) }

  subject(:decorator) { participation.decorate }

  describe "#to_s" do
    it "returns person name" do
      expect(decorator.to_s).to eq "Anna Admin"
    end

    it "returns person name even when in revoked state" do
      allow(participation.event).to receive(:revoked_participation_states).and_return(%w[revoked])
      participation.state = "revoked"
      expect(decorator.to_s).to eq "Anna Admin"
    end
  end
end
