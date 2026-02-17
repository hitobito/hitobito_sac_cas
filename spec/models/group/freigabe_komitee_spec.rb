# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Group::FreigabeKomitee do
  let(:group) { groups(:bluemlisalp_freigabekomitee) }

  context "create" do
    it "enqueues CreateApprovalCommissionResponsibilitiesJob if its the first freigabekomitee in layer" do
      matterhorn_touren_und_kurse = Fabricate(Group::SektionsTourenUndKurse.sti_name.to_sym,
        name: "Touren und Kurse Matterhorn", parent: groups(:matterhorn_funktionaere), layer_group: groups(:matterhorn))

      expect do
        Fabricate(Group::FreigabeKomitee.sti_name.to_sym, name: "FreigabeKomitee Matterhorn",
          parent: matterhorn_touren_und_kurse, layer_group: groups(:matterhorn))
      end.to change {
        Delayed::Job.where("handler like '%Event::CreateApprovalCommissionResponsibilitiesJob%'").count
      }
    end

    it "does not enqueue CreateApprovalCommissionResponsibilitiesJob if its the second freigabekomitee in layer" do
      expect do
        Fabricate(Group::FreigabeKomitee.sti_name.to_sym, name: "Zweites FreigabeKomitee",
          parent: groups(:bluemlisalp_touren_und_kurse), layer_group: groups(:bluemlisalp))
      end.to_not change {
        Delayed::Job.where("handler like '%Event::CreateApprovalCommissionResponsibilitiesJob%'").count
      }
    end
  end

  context "destroy" do
    it "does not allow destroy when event_approval_commission_responsibilities exist" do
      expect { group.destroy }.not_to change { described_class.unscoped.count }
      expect(group.errors.full_messages).to match_array ["Freigabekomitee kann nicht gelöscht werden, es " \
      "bestehen noch Zuständigkeiten"]
      expect(group.deleted_at).to be_nil
    end
  end

  it "has the phone_number_landline association provided by SacPhoneNumbers" do
    PhoneNumber.predefined_labels.each do |label|
      assoc = :"phone_number_#{label}"
      expect(Group::FreigabeKomitee.reflect_on_all_associations.map(&:name)).to include(assoc)
    end
  end
end
