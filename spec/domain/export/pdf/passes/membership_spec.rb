# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Export::Pdf::Passes::Membership do

  let(:member) { Fabricate(Group::SektionsMitglieder::Einzel.sti_name.to_sym, group: groups(:be_mitglieder)).person }
  let(:analyzer) { PDF::Inspector::Text.analyze(subject.render) }
  let(:year) { Time.zone.now.year }

  subject { described_class.new(member) }

  before do
    member.update!(first_name: 'Bob', last_name: 'Muster', address: 'Wasserstrasse 42', zip_code: '4242', town: 'Kanuto')
  end

  it 'sanitizes filename' do
    expect(subject.filename).to eq "SAC-Mitgliederausweis-#{year}-bob_muster.pdf"
  end

  context 'text' do

    it 'renders membership pass' do
      expect(text_with_position).to match_array [
        [131, 634, "Mitgliederausweis 2023"],
        [161, 602, "CH-3000 Bern - info@sac-cas.ch - www.sac-cas.ch"],
        [41, 557, "Mitgliederjahre"],
        [156, 557, "#{member.membership_years}"],
        [41, 451, "#{member.first_name} #{member.last_name}"],
        [41, 423, "Wasserstrasse 42"],
        [41, 394, "4242 Kanuto"]
      ]
    end
  end

  private

  def text_with_position
    analyzer.positions.each_with_index.collect do |p, i|
      p.collect(&:round) + [analyzer.show_text[i]]
    end
  end

end

