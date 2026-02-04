#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "roles/_type_fields_sac_cas.html.haml" do
  include FormatHelper

  let(:dom) {
    Capybara::Node::Simple.new(@rendered)
  }
  let(:form_builder) { StandardFormBuilder.new(:role, role, view, {}) }

  before do
    allow(view).to receive(:f).and_return(form_builder)
    allow(view).to receive(:entry).and_return(role.decorate)
  end

  describe "pruefer role" do
    let(:role) { Group::FreigabeKomitee::Pruefer.new(group: Group::FreigabeKomitee.new) }

    it "has select for approval kinds" do
      render
      expect(dom).to have_field "Freigabestufen"
    end
  end

  describe "other role" do
    let(:role) { roles(:admin) }

    it "does not have select for approval kinds" do
      render
      expect(dom).not_to have_field "Freigabestufen"
    end
  end
end
