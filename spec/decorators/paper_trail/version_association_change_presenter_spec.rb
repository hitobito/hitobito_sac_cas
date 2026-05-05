#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe PaperTrail::VersionAssociationChangePresenter, :draper_with_helpers, versioning: true do
  let(:view_context) { ActionController::Base.new.view_context }
  let(:presenter) { PaperTrail::VersionAssociationChangePresenter.new(version, view_context) }

  before do
    PaperTrail.request.whodunnit = nil
    view_context.extend(FormatHelper)
  end

  subject { presenter.render }

  describe "Event::Approval" do
    let(:tour) { events(:section_tour) }
    let(:version) { PaperTrail::Version.where(main_id: tour.id).order(:created_at, :id).last }

    it "builds approve text" do
      tour.approvals.create!(freigabe_komitee: groups(:bluemlisalp_freigabekomitee),
        approval_kind: event_approval_kinds(:professional), approved: true)

      is_expected.to eq("<div>Freigabe Fachlich durch Freigabekomitee</div>")
    end

    it "builds refused text" do
      tour.approvals.create!(freigabe_komitee: groups(:bluemlisalp_freigabekomitee),
        approval_kind: event_approval_kinds(:professional), approved: false)

      is_expected.to eq("<div>Ablehnung Fachlich durch Freigabekomitee</div>")
    end

    it "builds self approved text" do
      tour.approvals.create!(freigabe_komitee: nil,
        approval_kind: event_approval_kinds(:professional), approved: false)

      is_expected.to eq("<div>Selbstfreigabe</div>")
    end
  end
end
