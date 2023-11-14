# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Role::MitgliedUniquenessValidation
  extend ActiveSupport::Concern

  included do
    validates :type, uniqueness: { scope: :person_id }
  end
end
