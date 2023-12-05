# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'
require_relative '../shared_examples_mitglied'

describe Group::SektionsMitglieder::Mitglied do
  it_behaves_like 'validates Mitglied timestamps'
end
