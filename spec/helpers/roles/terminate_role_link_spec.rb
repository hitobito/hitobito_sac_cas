# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Roles::TerminateRoleLink do
  context '#render' do
    {
      Group::Sektion => :bluemlisalp_mitglieder,
      Group::Ortsgruppe => :bluemlisalp_ortsgruppe_ausserberg_mitglieder
    }.each do |group_class, mitglieder_group_name|
      context "for #{group_class}" do
        it 'returns disabled button with translated tooltip' do
          role = Group::SektionsMitglieder::Mitglied.new(group: groups(mitglieder_group_name))
          expect(role).to receive(:terminatable?).and_return(true)
          expect(view).to receive(:can?).with(:terminate, role).and_return(false)

          expect(described_class.new(role, view).render).
            to match(/title="Für einen Austritt musst du dich an den Mitgliederdienst der Sektion wenden"/)
        end
      end
    end
  end
end
