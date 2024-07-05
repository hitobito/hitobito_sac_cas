# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacCas::MountedAttrs::EnumSelect, type: :helper do
  let(:config) { group.class.mounted_attr_configs.index_by(&:attr_name)[:section_canton] }
  let(:group) { described_class.new }
  let(:form) { StandardFormBuilder.new(:group, group, self, {}) }
  let(:markup) { MountedAttrs::EnumSelect.new(self, config, form).render }
  let(:node) { Capybara::Node::Simple.new(markup) }

  context Group::Sektion do
    it "does render select with full canton name" do
      expect(node).to have_select("group_section_canton", with_options: %w[Aargau Bern])
    end
  end

  context Group::Ortsgruppe do
    it "does render select with full canton name" do
      expect(node).to have_select("group_section_canton", with_options: %w[Aargau Bern])
    end
  end
end
