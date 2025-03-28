# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# == Schema Information
#
# Table name: event_roles
#
#  id               :integer          not null, primary key
#  label            :string
#  type             :string           not null
#  participation_id :integer          not null
#
# Indexes
#
#  index_event_roles_on_participation_id  (participation_id)
#  index_event_roles_on_type              (type)
#

# Kursteilnehmer
module Event::Tour::Role
  class Participant < ::Event::Role::Participant
    class << self
      # A tour participant is restricted because it may not just be added by
      # a leader, but only over the special application market view.
      def restricted?
        true
      end
    end
  end
end
