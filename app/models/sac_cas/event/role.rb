# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SacCas::Event::Role
  extend ActiveSupport::Concern

  prepended do
    after_save :create_event_paper_trail_version, if: :saved_change_to_type?
  end

  private

  def create_event_paper_trail_version
    PaperTrail::Version.create!(
      item: self,
      main: event,
      event: "update",
      object: attributes.to_yaml,
      object_changes: {"type" => saved_changes[:type]}.to_yaml
    )
  end
end
