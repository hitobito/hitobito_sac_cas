# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::CostReceipt do
  let(:receipt) { event_cost_receipts(:tankstelle) }

  describe "validations" do
    it "is valid" do
      expect(receipt).to be_valid
    end

    it "requires description" do
      receipt.description = nil

      expect(receipt).not_to be_valid
    end

    it "requires file" do
      receipt.file.detach

      expect(receipt).not_to be_valid
    end

    it "validates maximum file size" do
      file = Tempfile.new(["x", ".png"])
      File.write(file, "x" * 11.megabytes)
      receipt.file.attach(io: file, filename: "foo.png")

      expect(receipt).not_to be_valid
    end

    it "validates content type" do
      file = Tempfile.new(["x", ".exe"])
      File.write(file, "x")
      receipt.file.attach(io: file, filename: "foo.exe", content_type: "application/x-msdownload")

      expect(receipt).not_to be_valid
    end
  end
end
