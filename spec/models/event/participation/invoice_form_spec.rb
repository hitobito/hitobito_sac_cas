# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Event::Participation::InvoiceForm do
  let(:participant) { people(:mitglied) }
  let(:event) { Fabricate(:sac_open_course) }
  let(:participation) { Fabricate(:event_participation, event:, person: participant) }

  subject(:form) { described_class.new(participation) }

  describe "validations" do
    let(:required_attrs) {
      {
        reference_date: 10.days.ago,
        send_date: 3.days.ago,
        invoice_date: 1.day.ago,
        price_category: "price_member",
        price: 100
      }
    }

    before { form.attributes = required_attrs }

    it "is valid with all params set" do
      expect(form).to be_valid
    end

    [:reference_date, :send_date, :invoice_date, :price_category, :price].each do |attr|
      it "is invalid when #{attr} is nil" do
        form.attributes = required_attrs.merge(attr => nil)
        expect(form).not_to be_valid
      end
    end

    [:reference_date, :send_date, :invoice_date].each do |attr|
      it "is invalid when #{attr} is not a valid date" do
        form.attributes = required_attrs.merge(attr => "12.61.10281")
        expect(form).not_to be_valid
      end
    end

    it "is not valid if price category does not exist" do
      form.price_category = "this_price_category_does_not_exist"
      expect(form).not_to be_valid
    end
  end
end
