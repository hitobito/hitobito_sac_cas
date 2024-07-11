# frozen_string_literal: true

#
#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::TerminationNoSelfService do
  let(:params) { {} }
  let(:wizard) { nil } # we don't need a wizard for the model specs
  let(:subject) { described_class.new(wizard, **params) }

  it "is always invalid" do
    is_expected.not_to be_valid
  end
end
