# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Wizards
  module Registering
    extend ActiveSupport::Concern
    include Wizards::Personal

    included do
      attribute :group
      validates_presence_of :group, if: :last_step?
    end

    def no_self_service?
      group.children.any? { |child| child.is_a?(Group::SektionsNeuanmeldungenSektion) }
    end
  end
end
