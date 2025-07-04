# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Memberships::SwitchStammZusatzsektion do
  include ActiveJob::TestHelper
  let(:backoffice) { false }
  let(:matterhorn) { groups(:matterhorn) }
  let(:params) { {} }

  let(:wizard) do
    described_class.new(current_step: @current_step.to_i, backoffice: true, person:, **params)
  end

  def stammsektion = person.sac_membership.stammsektion

  def zusatzsektion = person.sac_membership.zusatzsektion_roles.first.group.parent

  describe "persisting" do
    before do
      @current_step = 1
      params["choose_sektion"] = {group_id: matterhorn.id}
    end

    context "single person" do
      let(:person) { people(:mitglied) }

      it "inherits from Wizards::Memberships::SwitchStammsektion" do
        expect(wizard).to be_a(Wizards::Memberships::SwitchStammsektion)
      end

      it "switches stammsektion" do
        expect { expect(wizard.save!).to eq true }
          .to change { stammsektion.name }.from("SAC Blüemlisalp").to("SAC Matterhorn")
          .and change { zusatzsektion.name }.from("SAC Matterhorn").to("SAC Blüemlisalp")
          .and not_change { Role.count }
      end

      it "does not send email" do
        expect { expect(wizard.save!).to eq true }.not_to have_enqueued_email
      end

      describe "groups" do
        let(:ausserberg_mitglieder) { groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder) }

        it "returns all zusatzsektions" do
          Fabricate(
            Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
            group: ausserberg_mitglieder,
            person: person
          )
          expect(wizard.groups.map(&:name)).to match_array ["SAC Blüemlisalp Ausserberg", "SAC Matterhorn"]
        end

        it "exludes zusatzsektion if beitragkategorie does not match stammsektion beitragskategorie" do
          role = Fabricate(
            Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
            group: ausserberg_mitglieder,
            person: person
          )
          Role.where(id: role.id).update_all(beitragskategorie: :youth)

          expect(wizard.groups.map(&:name)).to match_array ["SAC Matterhorn"]
        end
      end
    end

    context "household" do
      let(:person) { people(:familienmitglied) }
      let(:familienmitglied2) { people(:familienmitglied2) }

      it "switches stammsektion" do
        expect { expect(wizard.save!).to eq true }
          .to change { stammsektion.name }.from("SAC Blüemlisalp").to("SAC Matterhorn")
          .and change { zusatzsektion.name }.from("SAC Matterhorn").to("SAC Blüemlisalp")
          .and change { familienmitglied2.sac_membership.stammsektion.name }.from("SAC Blüemlisalp").to("SAC Matterhorn")
          .and change { familienmitglied2.sac_membership.zusatzsektion_roles.first.group.parent.name }.from("SAC Matterhorn").to("SAC Blüemlisalp")
          .and not_change { Role.count }
      end

      it "does not send email" do
        expect { expect(wizard.save!).to eq true }.not_to have_enqueued_email
      end
    end
  end
end
