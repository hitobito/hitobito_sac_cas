# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tour::ApprovalForm do
  let(:user) { people(:tourenchef) }
  let(:tour) { events(:section_tour) }
  let(:form) { described_class.new(tour, user) }
  let(:komitee) { groups(:bluemlisalp_freigabekomitee) }

  def create_pruefer(approval_kinds)
    Group::FreigabeKomitee::Pruefer.create!(group: komitee, person: user, approval_kinds: approval_kinds)
  end

  def create_approval(kind, approved)
    tour.approvals.create!(approval_kind: event_approval_kinds(kind), approved: approved, freigabe_komitee: komitee)
  end

  def find_approval(kind)
    tour.approvals.find { |a| a.approval_kind == event_approval_kinds(kind) }
  end

  def expect_no_permissions(komitee_approval)
    expect(komitee_approval.approval_kind_approvals.size).to eq(3)

    aka1 = komitee_approval.approval_kind_approvals.first
    expect_kind_approval(aka1, :professional, responsible: false, approvable: false)
    aka2 = komitee_approval.approval_kind_approvals.second
    expect_kind_approval(aka2, :security, responsible: false, approvable: false)
    aka3 = komitee_approval.approval_kind_approvals.third
    expect_kind_approval(aka3, :editorial, responsible: false, approvable: false)
  end

  def expect_kind_approval(approval_kind_approval, kind, responsible:, approvable:)
    expect(approval_kind_approval.approval_kind).to eq(event_approval_kinds(kind))
    expect(approval_kind_approval.responsible).to eq(responsible)
    expect(approval_kind_approval.approvable).to eq(approvable)
  end

  def expect_disciplines_target_groups(komitee_approval, expected)
    expect(komitee_approval.disciplines_target_groups.map { |tuple| tuple.map(&:to_s) }).to eq(expected)
  end

  context "draft" do
    before { tour.update!(state: :draft) }

    context "as leiter" do
      it "builds object tree without permissions" do
        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.freigabe_komitee).to eq(komitee)
        expect_disciplines_target_groups(komitee_approval, [
          ["Wandern", "Familien (FaBe)"],
          ["Wandern", "Kinder (KiBe)"]
        ])
        expect_no_permissions(komitee_approval)
      end
    end

    context "as pruefer" do
      before { create_pruefer(event_approval_kinds(:professional, :security, :editorial)) }

      it "builds object tree without permissions" do
        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.freigabe_komitee).to eq(komitee)
        expect_disciplines_target_groups(komitee_approval, [
          ["Wandern", "Familien (FaBe)"],
          ["Wandern", "Kinder (KiBe)"]
        ])
        expect_no_permissions(komitee_approval)
      end

      it "lists only responsible komitees" do
        {bluemlisalp_wandern_familien_subito: "Komitee Familien Subito",
         bluemlisalp_klettern_familien: "Komitee Familien Klettern",
         bluemlisalp_wandern_senioren: "Komitee Senioren Wandern"}.each do |resp, name|
          Group::FreigabeKomitee.create!(name: name,
            parent: groups(:bluemlisalp_touren_und_kurse)).tap do |other|
            event_approval_commission_responsibilities(resp).update!(freigabe_komitee: other)
            Group::FreigabeKomitee::Pruefer.create!(group: other, person: user,
              approval_kinds: event_approval_kinds(:professional, :security))
          end
        end

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.freigabe_komitee).to eq(komitee)
        expect_disciplines_target_groups(komitee_approval, [
          ["Wandern", "Familien (FaBe)"],
          ["Wandern", "Kinder (KiBe)"]
        ])
      end
    end
  end

  context "review" do
    before { tour.update!(state: :review) }

    context "as pruefer" do
      it "builds object tree with all permissions" do
        create_pruefer(event_approval_kinds(:professional, :security, :editorial))

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.freigabe_komitee).to eq(komitee)
        expect_disciplines_target_groups(komitee_approval, [
          ["Wandern", "Familien (FaBe)"],
          ["Wandern", "Kinder (KiBe)"]
        ])
        expect(komitee_approval.approval_kind_approvals.size).to eq(3)
        aka1 = komitee_approval.approval_kind_approvals.first
        expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
        aka2 = komitee_approval.approval_kind_approvals.second
        expect_kind_approval(aka2, :security, responsible: true, approvable: true)
        aka3 = komitee_approval.approval_kind_approvals.third
        expect_kind_approval(aka3, :editorial, responsible: true, approvable: true)
      end

      it "builds object tree with partial permissions" do
        create_pruefer(event_approval_kinds(:professional, :editorial))

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.approval_kind_approvals.size).to eq(3)
        aka1 = komitee_approval.approval_kind_approvals.first
        expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
        aka2 = komitee_approval.approval_kind_approvals.second
        expect_kind_approval(aka2, :security, responsible: false, approvable: false)
        aka3 = komitee_approval.approval_kind_approvals.third
        expect_kind_approval(aka3, :editorial, responsible: true, approvable: false)
      end

      it "builds object tree with partial permissions and existing approvals" do
        create_pruefer(event_approval_kinds(:professional, :editorial))
        create_approval(:professional, true)
        create_approval(:security, true)

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.approval_kind_approvals.size).to eq(3)
        aka1 = komitee_approval.approval_kind_approvals.first
        expect_kind_approval(aka1, :professional, responsible: true, approvable: false)
        expect(aka1.approval.approval_kind).to eq(event_approval_kinds(:professional))
        expect(aka1.approval.approved).to be(true)
        aka2 = komitee_approval.approval_kind_approvals.second
        expect_kind_approval(aka2, :security, responsible: false, approvable: false)
        expect(aka2.approval.approval_kind).to eq(event_approval_kinds(:security))
        expect(aka2.approval.approved).to be(true)
        aka3 = komitee_approval.approval_kind_approvals.third
        expect_kind_approval(aka3, :editorial, responsible: true, approvable: true)
        expect(aka3.approval).to be_nil
      end

      it "builds object tree with partial permissions and existing rejection" do
        create_pruefer(event_approval_kinds(:professional, :editorial))
        create_approval(:professional, false)

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.approval_kind_approvals.size).to eq(3)
        aka1 = komitee_approval.approval_kind_approvals.first
        expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
        aka2 = komitee_approval.approval_kind_approvals.second
        expect_kind_approval(aka2, :security, responsible: false, approvable: false)
        aka3 = komitee_approval.approval_kind_approvals.third
        expect_kind_approval(aka3, :editorial, responsible: true, approvable: false)
      end

      it "builds object tree with partial permissions and existing approvals and rejection" do
        create_pruefer(event_approval_kinds(:professional, :editorial))
        create_approval(:professional, true)
        create_approval(:security, false)

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.approval_kind_approvals.size).to eq(3)
        aka1 = komitee_approval.approval_kind_approvals.first
        expect_kind_approval(aka1, :professional, responsible: true, approvable: false)
        expect(aka1.approval.approval_kind).to eq(event_approval_kinds(:professional))
        expect(aka1.approval.approved).to be(true)
        aka2 = komitee_approval.approval_kind_approvals.second
        expect_kind_approval(aka2, :security, responsible: false, approvable: false)
        expect(aka2.approval.approval_kind).to eq(event_approval_kinds(:security))
        expect(aka2.approval.approved).to be(false)
        aka3 = komitee_approval.approval_kind_approvals.third
        expect_kind_approval(aka3, :editorial, responsible: true, approvable: false)
        expect(aka3.approval).to be_nil
      end

      it "builds object tree without deleted approval kinds" do
        create_pruefer(event_approval_kinds(:professional, :security, :editorial))
        event_approval_kinds(:security).destroy!

        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.approval_kind_approvals.size).to eq(2)
        aka1 = komitee_approval.approval_kind_approvals.first
        expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
        aka2 = komitee_approval.approval_kind_approvals.second
        expect_kind_approval(aka2, :editorial, responsible: true, approvable: true)
      end

      context "with multiple komitees" do
        let!(:other_komitee) do
          Group::FreigabeKomitee.create!(name: "Komitee 2",
            parent: groups(:bluemlisalp_touren_und_kurse)).tap do |other|
            event_approval_commission_responsibilities(:bluemlisalp_wandern_familien).update!(freigabe_komitee: other)
          end
        end

        context "and multiple pruefer roles" do
          it "builds object tree with matching permissions" do
            create_pruefer(event_approval_kinds(:professional, :security, :editorial))
            Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
              approval_kinds: [event_approval_kinds(:professional)])
            Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
              approval_kinds: [event_approval_kinds(:security)])

            expect(form.komitee_approvals.size).to eq(2)
            komitee_approval = form.komitee_approvals.first
            expect(komitee_approval.freigabe_komitee).to eq(komitee)
            expect_disciplines_target_groups(komitee_approval, [
              ["Wandern", "Kinder (KiBe)"]
            ])
            expect(komitee_approval.approval_kind_approvals.size).to eq(3)
            aka1 = komitee_approval.approval_kind_approvals.first
            expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
            aka2 = komitee_approval.approval_kind_approvals.second
            expect_kind_approval(aka2, :security, responsible: true, approvable: true)
            aka3 = komitee_approval.approval_kind_approvals.third
            expect_kind_approval(aka3, :editorial, responsible: true, approvable: true)

            komitee_approval = form.komitee_approvals.second
            expect(komitee_approval.freigabe_komitee).to eq(other_komitee)
            expect_disciplines_target_groups(komitee_approval, [
              ["Wandern", "Familien (FaBe)"]
            ])
            expect(komitee_approval.approval_kind_approvals.size).to eq(3)
            aka1 = komitee_approval.approval_kind_approvals.first
            expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
            aka2 = komitee_approval.approval_kind_approvals.second
            expect_kind_approval(aka2, :security, responsible: true, approvable: true)
            aka3 = komitee_approval.approval_kind_approvals.third
            expect_kind_approval(aka3, :editorial, responsible: false, approvable: false)
          end
        end

        context "but only one pruefer role" do
          it "builds object tree with matching permissions" do
            create_pruefer([event_approval_kinds(:professional)])

            expect(form.komitee_approvals.size).to eq(2)
            komitee_approval = form.komitee_approvals.first
            expect(komitee_approval.freigabe_komitee).to eq(komitee)
            expect_disciplines_target_groups(komitee_approval, [
              ["Wandern", "Kinder (KiBe)"]
            ])
            expect(komitee_approval.approval_kind_approvals.size).to eq(3)
            aka1 = komitee_approval.approval_kind_approvals.first
            expect_kind_approval(aka1, :professional, responsible: true, approvable: true)
            aka2 = komitee_approval.approval_kind_approvals.second
            expect_kind_approval(aka2, :security, responsible: false, approvable: false)
            aka3 = komitee_approval.approval_kind_approvals.third
            expect_kind_approval(aka3, :editorial, responsible: false, approvable: false)

            komitee_approval = form.komitee_approvals.second
            expect(komitee_approval.freigabe_komitee).to eq(other_komitee)
            expect_disciplines_target_groups(komitee_approval, [
              ["Wandern", "Familien (FaBe)"]
            ])
            expect(komitee_approval.approval_kind_approvals.size).to eq(3)
            aka1 = komitee_approval.approval_kind_approvals.first
            expect_kind_approval(aka1, :professional, responsible: false, approvable: false)
            aka2 = komitee_approval.approval_kind_approvals.second
            expect_kind_approval(aka2, :security, responsible: false, approvable: false)
            aka3 = komitee_approval.approval_kind_approvals.third
            expect_kind_approval(aka3, :editorial, responsible: false, approvable: false)
          end
        end
      end
    end

    context "as leiter" do
      it "builds object tree without permissions" do
        expect(form.komitee_approvals.size).to eq(1)
        komitee_approval = form.komitee_approvals.first
        expect(komitee_approval.freigabe_komitee).to eq(komitee)
        expect_disciplines_target_groups(komitee_approval, [
          ["Wandern", "Familien (FaBe)"],
          ["Wandern", "Kinder (KiBe)"]
        ])
        expect_no_permissions(komitee_approval)
      end
    end
  end

  context "approved" do
    before { tour.update!(state: :approved) }

    context "as pruefer" do
      before { create_pruefer(event_approval_kinds(:professional, :security, :editorial)) }

      context "with komitee approvals" do
        before do
          [:professional, :security, :editorial].each do |kind|
            create_approval(kind, true)
          end
        end

        it "builds object tree without permissions" do
          expect(form.komitee_approvals.size).to eq(1)
          komitee_approval = form.komitee_approvals.first
          expect(komitee_approval.freigabe_komitee).to eq(komitee)
          expect_disciplines_target_groups(komitee_approval, [
            ["Wandern", "Familien (FaBe)"],
            ["Wandern", "Kinder (KiBe)"]
          ])
          expect(form.self_approval).to be_nil
          expect_no_permissions(komitee_approval)

          aka1 = komitee_approval.approval_kind_approvals.first
          expect(aka1.approval.approval_kind).to eq(event_approval_kinds(:professional))
          expect(aka1.approval.approved).to be(true)
        end
      end

      context "with self approval" do
        let!(:approval) do
          tour.approvals.create!(approved: true)
        end

        it "builds object tree without permissions" do
          expect(form.komitee_approvals.size).to eq(0)
          expect(form.self_approval).to eq(approval)
        end
      end
    end
  end

  context "saving" do
    before { tour.update!(state: :review) }

    def build_check_attrs(professional, security, editorial)
      {
        internal_comment: "Tiptop",
        komitee_approvals_attributes: {
          "0" => {
            freigabe_komitee_id: komitee.id,
            approval_kind_approvals_attributes: {
              "0" => {approval_kind_id: event_approval_kinds(:professional).id, checked: professional},
              "1" => {approval_kind_id: event_approval_kinds(:security).id, checked: security},
              "2" => {approval_kind_id: event_approval_kinds(:editorial).id, checked: editorial}
            }
          }
        }
      }
    end

    it "saves checked approvals" do
      create_pruefer(event_approval_kinds(:professional, :security, :editorial))

      form.attributes = build_check_attrs(true, true, false)

      expect { form.save("approve") }.to change { tour.approvals.count }.by(2)

      expect(tour.reload.state).to eq("review")
      expect(tour.internal_comment).to eq("Tiptop")

      approval1 = find_approval(:professional)
      expect(approval1.approved).to eq(true)
      expect(approval1.freigabe_komitee).to eq(komitee)
      expect(approval1.creator).to eq(user)
      approval2 = find_approval(:security)
      expect(approval2.approved).to eq(true)
      expect(approval2.freigabe_komitee).to eq(komitee)
      expect(approval2.creator).to eq(user)
    end

    it "can approve everything at once" do
      create_pruefer(event_approval_kinds(:professional, :security, :editorial))

      form.attributes = build_check_attrs(true, true, true)

      expect { form.save("approve") }.to change { tour.approvals.count }.by(3)

      expect(tour.reload.state).to eq("approved")
      expect(tour.internal_comment).to eq("Tiptop")
    end

    it "does not save approvals if previous are unchecked" do
      create_pruefer(event_approval_kinds(:professional, :security, :editorial))

      form.attributes = build_check_attrs(false, true, false)

      expect { form.save("approve") }.not_to change { tour.approvals.count }

      expect(tour.reload.internal_comment).to eq("Tiptop")
    end

    it "saves checked rejections" do
      create_pruefer(event_approval_kinds(:professional, :security, :editorial))

      form.attributes = build_check_attrs(true, true, false)

      expect { form.save("reject") }.to change { tour.approvals.count }.by(2)

      expect(tour.reload.state).to eq("draft")
      expect(tour.internal_comment).to eq("Tiptop")

      approval1 = find_approval(:professional)
      expect(approval1.approved).to eq(false)
      expect(approval1.freigabe_komitee).to eq(komitee)
      approval2 = find_approval(:security)
      expect(approval2.approved).to eq(false)
      expect(approval2.freigabe_komitee).to eq(komitee)
    end

    it "changes rejections to approvals" do
      create_pruefer(event_approval_kinds(:professional, :security, :editorial))
      approval1 = create_approval(:professional, false)
      approval2 = create_approval(:security, false)
      approval1_at = approval1.created_at

      form.attributes = build_check_attrs(true, true, false)

      expect { form.save("approve") }.not_to change { tour.approvals.count }

      approval1.reload
      expect(approval1.approved).to eq(true)
      expect(approval1.creator).to eq(user)
      expect(approval1.created_at).to be > approval1_at
      approval2.reload
      expect(approval2.approved).to eq(true)
      expect(approval2.creator).to eq(user)
    end

    it "does not change approvals to rejections" do
      create_pruefer(event_approval_kinds(:professional, :security, :editorial))
      create_approval(:professional, true)
      create_approval(:security, true)

      form.attributes = build_check_attrs(true, true, false)

      expect { form.save("reject") }.not_to change { tour.approvals.count }

      approval1 = find_approval(:professional)
      expect(approval1.approved).to eq(true)
      expect(approval1.creator).to be_nil
      approval2 = find_approval(:security)
      expect(approval2.approved).to eq(true)
      expect(approval2.creator).to be_nil
    end

    it "cannot approve everything with partial permissions" do
      create_pruefer(event_approval_kinds(:professional, :editorial))

      form.attributes = build_check_attrs(true, true, true)

      expect { form.save("approve") }.to change { tour.approvals.count }.by(1)

      expect(tour.reload.state).to eq("review")

      approval1 = find_approval(:professional)
      expect(approval1.approved).to eq(true)
      expect(approval1.freigabe_komitee).to eq(komitee)
    end

    it "can approve last kind with partial permissions and existing approvals" do
      create_pruefer(event_approval_kinds(:professional, :editorial))
      create_approval(:professional, true)
      create_approval(:security, true)

      form.attributes = build_check_attrs(false, false, true)

      expect { form.save("approve") }.to change { tour.approvals.count }.by(1)

      expect(tour.reload.state).to eq("approved")

      approval1 = find_approval(:editorial)
      expect(approval1.approved).to eq(true)
      expect(approval1.freigabe_komitee).to eq(komitee)
    end

    it "cannot approve last kind with partial permissions and existing rejection" do
      create_pruefer(event_approval_kinds(:professional, :editorial))
      create_approval(:professional, true)
      create_approval(:security, false)

      form.attributes = build_check_attrs(false, false, true)

      expect { form.save("approve") }.not_to change { tour.approvals.count }

      expect(tour.reload.state).to eq("review")
    end

    context "with multiple komitees" do
      let!(:other_komitee) do
        Group::FreigabeKomitee.create!(name: "Komitee 2",
          parent: groups(:bluemlisalp_touren_und_kurse)).tap do |other|
          event_approval_commission_responsibilities(:bluemlisalp_wandern_familien).update!(freigabe_komitee: other)
        end
      end

      context "and multiple pruefer roles" do
        it "builds object tree with matching permissions" do
          create_pruefer(event_approval_kinds(:professional, :security, :editorial))
          Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
            approval_kinds: [event_approval_kinds(:professional)])
          Group::FreigabeKomitee::Pruefer.create!(group: other_komitee, person: user,
            approval_kinds: [event_approval_kinds(:security)])

          form.attributes = {
            komitee_approvals_attributes: {
              "0" => {
                freigabe_komitee_id: komitee.id,
                approval_kind_approvals_attributes: {
                  "0" => {approval_kind_id: event_approval_kinds(:professional).id, checked: true},
                  "1" => {approval_kind_id: event_approval_kinds(:security).id, checked: true},
                  "2" => {approval_kind_id: event_approval_kinds(:editorial).id, checked: false}
                }
              },
              "1" => {
                freigabe_komitee_id: other_komitee.id,
                approval_kind_approvals_attributes: {
                  "0" => {approval_kind_id: event_approval_kinds(:professional).id, checked: true},
                  "1" => {approval_kind_id: event_approval_kinds(:security).id, checked: true},
                  "2" => {approval_kind_id: event_approval_kinds(:editorial).id, checked: true}
                }
              }
            }
          }

          expect { form.save("approve") }.to change { tour.approvals.count }.by(4)

          expect(tour.reload.state).to eq("review")

          expect(tour.approvals.map(&:approval_kind)).to match_array(
            [event_approval_kinds(:professional), event_approval_kinds(:security),
              event_approval_kinds(:professional), event_approval_kinds(:security)]
          )
          expect(tour.approvals.map(&:freigabe_komitee)).to match_array(
            [komitee, komitee, other_komitee, other_komitee]
          )
        end
      end
    end

    it "as tourenchef only saves internal comment" do
      form.attributes = build_check_attrs(true, true, false)

      expect { form.save("approve") }.not_to change { tour.approvals.count }

      expect(tour.reload.internal_comment).to eq("Tiptop")
    end
  end
end
