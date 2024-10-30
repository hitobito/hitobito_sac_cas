# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

ENV["RAILS_STRUCTURED_ADDRESSES"] = "1"
ENV["RAILS_ADDRESS_MIGRATION"] = "0"
ENV["TZ"] = "Europe/Zurich"
# ENV["RAILS_TZ"] = "Europe/Zurich"
# ActiveRecord::Base.default_timezone = "Europe/Zurich"

load File.expand_path("../app_root.rb", __dir__)
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require File.join(ENV.fetch("APP_ROOT", nil), "spec", "spec_helper.rb")
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[HitobitoSacCas::Wagon.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = File.expand_path("fixtures", __dir__)

  # disable 2FA for admins in test env since login is used in feature specs
  config.before do
    allow(Group::Geschaeftsstelle::Admin).to receive(:two_factor_authentication_enforced).and_return(false)
  end
end

def ci? = ENV["CI"] == "true"
