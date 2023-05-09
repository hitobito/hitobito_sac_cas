# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


Fabrication.configure do |config|
  config.fabricator_path = ['spec/fabricators',
                            '../hitobito_sac_cas/spec/fabricators']
  config.path_prefix = Rails.root
end
