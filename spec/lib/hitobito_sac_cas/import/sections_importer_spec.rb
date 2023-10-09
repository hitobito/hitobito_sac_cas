# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'
require_relative '../../../../lib/hitobito_sac_cas/import/sections_importer.rb'

describe Import::SectionsImporter do
  let(:file) { file_fixture('bluemlisalp_sections.xlsx') }
  let(:importer) { described_class.new(file, output: double(puts: nil)) }

  it 'imports sections' do
    expect { importer.import! }.
      to change { Group::Sektion.count }.by(1).
      and change { Group::Ortsgruppe.count }.by(1)
  end

  it 'imports section_canton attribute' do
    importer.import!

    expect(Group::Sektion.find_by!(name: 'SAC Blüemlisalp').section_canton ).
      to eq 'BE'
  end
end
