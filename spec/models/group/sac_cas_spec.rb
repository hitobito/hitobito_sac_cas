# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Group::SacCas do
  let(:group) { groups(:root) }

  context "validations" do
    context "sac_newsletter_mailing_list_id" do
      it "allows empty value" do
        expect(group).to be_valid
      end

      it "allows value of group mailing_list" do
        list = Fabricate(:mailing_list, group: group)
        group.sac_newsletter_mailing_list_id = list.id
        expect(group).to be_valid
      end

      it "does not allow value from other groups" do
        list = Fabricate(:mailing_list, group: groups(:geschaeftsstelle))
        group.sac_newsletter_mailing_list_id = list.id
        expect(group).not_to be_valid
        expect(group).to have(1).error_on("sac_newsletter_mailing_list_id")
      end
    end

    context "sac_magazine_mailing_list_id" do
      it "allows empty value" do
        expect(group).to be_valid
      end

      it "allows value of group mailing_list" do
        list = Fabricate(:mailing_list, group: group)
        group.sac_magazine_mailing_list_id = list.id
        expect(group).to be_valid
      end

      it "does not allow value from other groups" do
        list = Fabricate(:mailing_list, group: groups(:geschaeftsstelle))
        group.sac_magazine_mailing_list_id = list.id
        expect(group).not_to be_valid
        expect(group).to have(1).error_on("sac_magazine_mailing_list_id")
      end
    end

    context "sac_fundraising_mailing_list_id" do
      it "allows empty value" do
        expect(group).to be_valid
      end

      it "allows value of group mailing_list" do
        list = Fabricate(:mailing_list, group: group)
        group.sac_fundraising_mailing_list_id = list.id
        expect(group).to be_valid
      end

      it "does not allow value from other groups" do
        list = Fabricate(:mailing_list, group: groups(:geschaeftsstelle))
        group.sac_fundraising_mailing_list_id = list.id
        expect(group).not_to be_valid
        expect(group).to have(1).error_on("sac_fundraising_mailing_list_id")
      end
    end

    context "course_admin_email" do
      it "allows value of group mailing_list" do
        group.course_admin_email = "test@example.com"
        expect(group).to be_valid
      end

      it "does not allow invalid email" do
        group.course_admin_email = "invalid"
        expect(Truemail).to receive(:valid?).and_return(false)
        expect(group).to have(1).error_on(:course_admin_email)
        expect(group.errors.full_messages).to eq ["E-Mail Kursadministration ist nicht gültig"]
      end
    end
  end
end
