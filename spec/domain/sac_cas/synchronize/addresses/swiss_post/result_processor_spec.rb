# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Synchronize::Addresses::SwissPost::ResultProcessor do
  let(:result) {
    Wagons.find("sac_cas").root.join("spec", "support", "synchronize", "addresses", "swiss_post", "result.txt").read
  }
  let(:mitglied) { people(:mitglied) }
  let(:options) { {col_sep: "\t", row_sep: "\r\n", headers: true} }
  let(:log_entry) { HitobitoLogEntry.last }
  let(:log_entry_attrs) { {category: "cleanup", subject: mitglied, level: "info"} }
  let(:invalid_tag) { PersonTags::Validation.post_address_check_invalid }

  def process_with
    data = CSV.parse(result, **options)
    yield data
    described_class.new(data.to_csv(**options), invalid_tag).process
  end

  subject(:processor) { described_class.new(result, invalid_tag) }

  describe "single field update" do
    it "updates canton" do
      mitglied.update!(canton: "be")
      expect do
        processor.process
      end.to change { mitglied.reload.canton }.from("be").to("ag")
    end
  end
end
