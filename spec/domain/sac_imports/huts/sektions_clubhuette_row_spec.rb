# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::Huts::SektionsClubhuetteRow do
  let(:importer) { described_class.new(row, csv_report: double) }

  let(:row) do
    SacImports::Nav5HutsImporter::HEADERS.keys.index_with { |_symbol| nil }.merge(
      contact_navision_id: "99993750",
      contact_name: "3750 SAC Blüemlisalp",
      hut_category: "SAC Clubhütte",
      verteilercode: "4000",
      related_navision_id: "00000036",
      related_last_name: "Blüemlisalphütte SAC",
      created_at: "06/10/2022"
    )
  end

  let!(:sektion) { Fabricate(Group::Sektion.sti_name.to_sym, navision_id: 99993750, foundation_year: 1980, name: "foobar Sektion") }

  before do
    sektion.children.find_by(type: Group::SektionsFunktionaere.sti_name).update_columns(layer_group_id: sektion.id)
    sektion.children.find_by(type: Group::SektionsFunktionaere.sti_name).children.create!(type: Group::SektionsClubhuetten, layer_group_id: sektion.id)
  end

  it "imports group" do
    expect { importer.import! }
      .to change { Group.count }.by(1)

    group = sektion.reload.descendants.find_by(navision_id: 36)

    expect(group).to be_present
    expect(group.name).to eq("Blüemlisalphütte SAC")
  end

  it "does not import twice" do
    expect { importer.import! }
      .to change { Group.count }.by(1)

    group = sektion.reload.descendants.find_by(navision_id: 36)

    expect(group).to be_present
    expect(group.name).to eq("Blüemlisalphütte SAC")

    expect { importer.import! }
      .to_not change { Group.count }
  end
end
