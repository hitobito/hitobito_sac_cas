# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Roles::SektionsfunktionaereOnboardingMails do
  let(:person) { Fabricate(:person) }
  let(:group) { groups(:bluemlisalp_funktionaere) }
  let(:role) { Group::SektionsFunktionaere::Praesidium.new(person:, group:) }

  it "delivers mail when send_onboarding_mail is set to true" do
    role.send_onboarding_mail = true
    expect { role.save! }.to have_enqueued_mail(People::SektionsfunktionaereMailer, :praesidium_onboarding)
  end

  it "does not deliver mail when send_onboarding_mail is false" do
    role.send_onboarding_mail = false
    expect { role.save! }.not_to have_enqueued_mail(People::SektionsfunktionaereMailer, :praesidium_onboarding)
  end
end
