# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe CornercardUpload do
  let(:person) { Fabricate(:person) }

  describe "associations" do
    it "belongs to person" do
      upload = described_class.create!(person: person)
      expect(upload.person).to eq person
    end

    it "requires person" do
      upload = described_class.new
      expect(upload).not_to be_valid
      expect(upload.errors[:person]).to be_present
    end

    it "is destroyed together with the person" do
      upload = described_class.create!(person: person)
      person.destroy!
      expect(described_class.exists?(upload.id)).to be false
    end
  end

  describe "uploaded_at" do
    it "is nil for new uploads" do
      upload = described_class.create!(person: person)
      expect(upload.uploaded_at).to be_nil
    end

    it "can be set" do
      upload = described_class.create!(person: person, uploaded_at: Time.zone.now)
      expect(upload.reload.uploaded_at).to be_present
    end
  end

  describe ".pending" do
    it "contains only uploads without uploaded_at" do
      pending_upload = described_class.create!(person: person)
      uploaded_upload = described_class.create!(person: Fabricate(:person), uploaded_at: Time.zone.now)

      expect(described_class.pending).to eq [pending_upload]
      expect(described_class.pending).to_not include(uploaded_upload)
    end
  end
end
