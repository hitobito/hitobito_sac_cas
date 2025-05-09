# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

desc "SAC CLI"
task cli: ["cli:setup", :environment] do
  require "tty/cli"
  TTY::Cli.new.run
end

namespace :cli do
  task :setup do
    # Files in lib/tty are not autoloaded by zeitwerk as lib is not configured as a autoload_path.
    # As we don't want to manually require files, we add /lib to the autoload_paths.
    # We do this here as to not pollute the environment of the regular application context.
    ActiveSupport::Inflector.inflections { |i| i.acronym("TTY") }

    # loader = Rails.autoloaders.main
    lib_path = File.expand_path("..", __dir__)
    Rails.application.config.autoload_paths << lib_path
  end
end
