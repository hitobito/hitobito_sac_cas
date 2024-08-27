# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports::CallbackBlacklist
  CALLBACKS_TO_SKIP = {
    "Person" => {
      after_save: [:check_data_quality]
    },
    "Role::MitgliedCommon" => {
      after_create: [:check_data_quality],
      after_destroy: [:check_data_quality]
    }
  }

  # ATTENTION: only use this method when called from a rake task in the import scripts
  # as it will not re-enable the callbacks
  def self.remove
    CALLBACKS_TO_SKIP.each do |model, callbacks|
      callbacks.each do |callback_type, methods|
        methods.each do |method|
          model.skip_callback(callback_type, method)
        end
      end
    end
  end
end
