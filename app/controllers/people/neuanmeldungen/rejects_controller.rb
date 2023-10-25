# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People
  module Neuanmeldungen
    class RejectsController < HandlerController
      skip_authorization_check

      self.handler_class = People::Neuanmeldungen::Reject
      self.permitted_attrs = [:group_id, :ids, :note, :locale]

      def attributes
        super.merge(author: current_user)
      end
    end
  end
end
