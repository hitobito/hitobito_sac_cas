# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module People
  class AccountCompletionList
    def generate(people, host:)
      CSV.generate do |csv|
        csv << %w[person_id url]
        people.order(:id).find_each do |person|
          token = person.generate_token_for(:account_completion)
          url = Rails.application.routes.url_helpers.account_completion_url(token:, host:)
          csv << [person.id, url]
        end
      end
    end
  end
end
