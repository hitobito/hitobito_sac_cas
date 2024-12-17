# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MailingListAbility do
  context "manage main group abos" do
    it "is permitted when member with Schreibrecht" do
    end

    it "is denied when member without Schreibrecht" do
    end
  end

  context "manage sub group abos in same main group" do
    it "is denied when member with Schreibrecht" do
    end
  end

  context "manage foreign main group abos" do
    it "is denied when member with Schreibrecht" do
    end
  end
end
