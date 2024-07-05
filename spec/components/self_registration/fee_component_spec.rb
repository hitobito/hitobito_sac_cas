# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SelfRegistration::FeeComponent, type: :component do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:attrs) { {group: group, birthdays: []} }
  let(:registration) { SelfRegistration.new }

  subject(:component) { described_class.new(**attrs) }

  subject(:html) { render_inline(component) }

  it "does render" do
    expect(component).to be_render
  end

  it "does render title with section name" do
    expect(html).to have_css("h2.card-title", text: "Beiträge in der Sektion SAC Blüemlisalp")
  end

  it "does render birthdays if present" do
    attrs[:birthdays] = %w[1.1.2000 1.1.2001]
    expect(html).to have_css("li", text: "1.1.2000")
    expect(html).to have_css("li", text: "1.1.2001")
  end
end
