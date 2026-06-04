# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Sheet::Event::Participation do
  let(:view_context) { controller.view_context }

  context "Event::ParticipationsController" do
    before { allow(view_context).to receive(:controller).and_return(Event::ParticipationsController.new) }

    %w[show edit index].each do |action|
      context "#{action} action" do
        before { allow(view_context).to receive(:action_name).and_return(action) }

        it "#parent_sheet_for returns Sheet::Event" do
          expect(described_class.parent_sheet_for(view_context)).to eq Sheet::Event
        end
      end
    end

    %w[new create].each do |action|
      context "#{action} action" do
        before { allow(view_context).to receive(:action_name).and_return(action) }

        it "#parent_sheet_for returns nil" do
          expect(described_class.parent_sheet_for(view_context)).to be_nil
        end
      end
    end
  end

  context "other controllers" do
    before { allow(view_context).to receive(:controller).and_return(Event::Courses::InvoicesController.new) }

    %w[new create show edit index].each do |action|
      context "#{action} action" do
        before { allow(view_context).to receive(:action_name).and_return(action) }

        it "#parent_sheet_for returns Sheet::Event" do
          expect(described_class.parent_sheet_for(view_context)).to eq Sheet::Event
        end
      end
    end
  end
end
