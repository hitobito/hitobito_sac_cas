# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::SacMemberships::DestroyHouseholdsForInactiveMembershipsJob do
  let(:job) { described_class.new }
  let(:family_member) { people(:familienmitglied) }

  it "reschedules to tomorrow at 00:08" do
    subject.perform

    expect(subject.delayed_jobs.last.run_at).to eq(Time.zone.tomorrow
      .at_beginning_of_day
      .change(min: 8)
      .in_time_zone)
  end

  describe "#affected_family_people" do
    it "makes only 1 query" do
      expect_query_count { subject.affected_family_people.to_a }.to eq 1
    end

    context "with ended stammsektion roles" do
      it "includes the family" do
        family_member.sac_membership.stammsektion_role.update!(end_on: 10.days.ago)
        expect(subject.affected_family_people).to eq [family_member]
      end

      it "does not include the family person when having active roles as well" do
        old_membership = family_member.sac_membership.stammsektion_role
        old_membership.update!(end_on: 10.days.ago)
        active_membership = old_membership.dup
        active_membership.assign_attributes(start_on: 9.days.ago, end_on: 30.days.from_now)
        active_membership.save!

        expect(subject.affected_family_people).not_to include(family_member)
      end
    end

    context "with ended neuanmeldung roles" do
      before do
        family_member.roles.destroy_all
        family_member.update!(sac_family_main_person: true, household_key: "123")
        Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name.to_sym,
          person: family_member,
          beitragskategorie: :family,
          group: groups(:bluemlisalp_neuanmeldungen_sektion),
          start_on: 50.days.ago,
          end_on: 10.days.ago)
      end

      it "includes the family" do
        expect(subject.affected_family_people).to eq [family_member]
      end
    end

    context "neuanmeldung nv roles" do
      before do
        family_member.roles.destroy_all
        family_member.update!(sac_family_main_person: true, household_key: "123")
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: family_member,
          beitragskategorie: :family,
          group: groups(:bluemlisalp_neuanmeldungen_nv),
          start_on: 50.days.ago,
          end_on: 10.days.ago)
      end

      it "includes the family" do
        expect(subject.affected_family_people).to eq [family_member]
      end
    end

    context "with ended zusatzsektion roles" do
      before { family_member.sac_membership.zusatzsektion_roles.first.update!(end_on: 10.days.ago) }

      it "does not include the family" do
        expect(subject.affected_family_people).to be_empty
      end
    end

    context "without household key" do
      before do
        family_member.sac_membership.stammsektion_role.update!(end_on: 10.days.ago)
        family_member.update!(household_key: nil)
      end

      it "does not include the family" do
        expect(subject.affected_family_people).to be_empty
      end
    end

    context "with empty household key" do
      before do
        family_member.sac_membership.stammsektion_role.update!(end_on: 10.days.ago)
        family_member.update!(household_key: "")
      end

      it "does not include the family" do
        expect(subject.affected_family_people).to be_empty
      end
    end

    context "with multiple family members" do
      let(:family_member2) { people(:familienmitglied2) }

      before do
        family_member.sac_membership.stammsektion_role.update!(end_on: 10.days.ago)
        family_member2.sac_membership.stammsektion_role.update!(end_on: 10.days.ago)
      end

      it "returns distinct families based on household key" do
        expect(subject.affected_family_people.size).to eq 1
      end
    end
  end

  context "when performing job" do
    it "calls household destroy for each family" do
      allow(job).to receive(:affected_family_people).and_return([family_member, people(:familienmitglied2)])
      expect(family_member.household).to receive(:destroy).exactly(:once)
      expect(people(:familienmitglied2).household).to receive(:destroy).exactly(:once)
      job.perform
    end
  end
end
