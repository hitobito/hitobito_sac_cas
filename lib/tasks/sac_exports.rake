# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

namespace :sac_exports do
  desc "Write all"
  task write_seeds: [:read_from_int, :read_from_prod]

  desc "Reads and overrides custom_contents from int"
  task read_from_int: :environment do
    action_text_scope = ActionText::RichText.where(record_type: CustomContent::Translation.sti_name)

    SacExports::ClusterContext.new(:int).with_database do
      code = SacExports::SeedGenerator.new(CustomContent, keys: [:key]).generate_code
      code += SacExports::SeedGenerator.new(CustomContent::Translation,
        keys: [:custom_content_id, :locale]).generate_code
      code += SacExports::SeedGenerator.new(ActionText::RichText, scope: action_text_scope,
        keys: [:record_id, :record_type]).generate_code

      write(:custom_contents, code)
    end
  end

  desc "Reads and overrides tokens_and_apps and sac config from prod"
  task read_from_prod: :environment do
    SacExports::ClusterContext.new(:prod).with_database do
      code = SacExports::SeedGenerator.new(ServiceToken, keys: [:token]).generate_code
      code += SacExports::SeedGenerator.new(Oauth::Application, keys: [:uid]).generate_code
      write(:tokens_and_apps, code)

      code = SacExports::SeedGenerator.new(SacMembershipConfig, keys: [:id]).generate_code
      write(:sac_membership_configs, code)
    end
  end

  def write(seed, code)
    Wagons.find("sac_cas").root.join("db/seeds/#{seed}.rb").tap do |file|
      file.write(code)
      puts "Written to #{file}"
    end
  end
end
