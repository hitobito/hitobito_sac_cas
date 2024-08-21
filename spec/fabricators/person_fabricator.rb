# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# People in SAC are required to be older than 6 years, so we make sure they have such a birthday
Fabrication.manager[:person].append_or_update_attribute(:birthday, nil) { 24.years.ago }
# Nickname is not used, so set it nil
Fabrication.manager[:person].append_or_update_attribute(:nickname, nil)
