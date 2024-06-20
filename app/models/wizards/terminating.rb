# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Wizards
  module Terminating
    extend ActiveSupport::Concern
    include Wizards::Personal

    included do
      attribute :role
      validates_presence_of :role
    end

    def affected_roles
      raise 'Implement in subclass'
    end

    def no_self_service?
      affected_roles.any? { |role| role.layer_group.try(:mitglied_termination_by_section_only) }
    end

  end
end
