#  frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sww.

module SacCas::PersonResource
  extend ActiveSupport::Concern

  included do
    attribute :family_id, :string, writable: false, sortable: false, filterable: false
  end
end
