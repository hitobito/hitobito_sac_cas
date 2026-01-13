# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::TerminateSacMembershipForm do
  let(:person) { people(:mitglied) }

  subject(:form) { described_class.new(%w[now], person) }

  before do
    form.termination_reason_id = termination_reasons(:moved).id
    form.terminate_on = "now"
  end

  describe "validations" do
    context "mitglied" do
      let(:person) { people(:mitglied) }

      it "is valid" do
        expect(form).to be_valid
      end
    end

    context "familie" do
      let(:person) { people(:familienmitglied2) }

      it "is valid" do
        expect(form).to be_valid
      end

      it "is invalid if household would be invalid when removing person" do
        role = roles(:familienmitglied_kind)
        Roles::Termination.new(role:, terminate_on: Time.zone.today.end_of_year).call
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Nima Norgay hat einen Austritt geplant."]
      end

      it "is valid even if household would be invalid as only single person left" do
        people(:familienmitglied).destroy!
        expect(form).to be_valid
      end
    end
  end
end
