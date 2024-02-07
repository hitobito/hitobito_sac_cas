# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class People::Neuanmeldungen::Promoter
  class Condition
    attr_reader :person, :role

    def self.satisfied?(role)
      new(role).satisfied?
    end

    private

    def initialize(role)
      @role = role
      @person = role.person
    end

    def satisfied?
      raise NotImplementedError
    end
  end
end
