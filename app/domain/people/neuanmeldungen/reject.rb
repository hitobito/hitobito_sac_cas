# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People
  module Neuanmeldungen
    # Reject Neuanmeldungen
    #
    # In the given group for all People with the given people_ids:
    # - their Role gets terminated immediately
    # - their login gets disabled
    # - if a note was provided, it will be added to their Person notes
    #
    # Example:
    #   People::Neuanmeldungen::Reject.new(group: group, people_ids: people_ids, note: note).call
    #
    class Reject < Base
      attr_accessor :note, :author

      def call
        applicable_roles.each do |role|
          Role.transaction do
            role.destroy!(always_soft_destroy: true)
            role.person.update!(encrypted_password: nil)
            add_note(role.person)
          end
        end
      end

      private

      def add_note(person)
        return if note.blank?

        person.notes.create!(
          text: note,
          author: author || Person.new(id: 0)
        )
      end
    end
  end
end
