# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Event::ApprovalKindsController < SimpleCrudController
  self.permitted_attrs = [:name, :short_description, :order]

  self.sort_mappings = {
    name: "event_approval_kind_translations.name"
  }

  def self.model_class = Event::ApprovalKind
end
