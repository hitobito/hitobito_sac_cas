# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacImports::CallbackBlacklist do
  before do
    @model = double("Model")
    allow(@model).to receive(:skip_callback)

    stub_const("SacImports::CallbackBlacklist::CALLBACKS_TO_SKIP", {
      @model => {
        before_save: [:method1, :method2],
        after_create: [:method3]
      }
    })
  end

  describe ".remove" do
    it "skips the specified callbacks for each model" do
      SacImports::CallbackBlacklist.remove

      expect(@model).to have_received(:skip_callback).with(:before_save, :method1)
      expect(@model).to have_received(:skip_callback).with(:before_save, :method2)
      expect(@model).to have_received(:skip_callback).with(:after_create, :method3)
    end
  end
end
