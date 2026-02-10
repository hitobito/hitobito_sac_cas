# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Group::FreigabeKomitee::Pruefer do
  let(:role) { described_class.new }

  describe "#to_s" do
    it "returns approval_kinds in brackets" do
      role.approval_kinds = [event_approval_kinds(:professional), event_approval_kinds(:security)]
      expect(role.to_s).to eq "Prüfer*in (Fachlich, Sicherheit)"
    end

    it "returns super when no approval_kind is assigned" do
      expect(role.to_s).to eq "Prüfer*in"
    end
  end
end
