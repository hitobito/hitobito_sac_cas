# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Memberships
  class ChangeZusatzsektionToFamiliesController < ApplicationController
    before_action :authorize

    def create
      Memberships::ChangeZusatzsektionToFamily.new(role).save!

      redirect_to group_person_path(role.person, group_id: role.group_id), notice: t(".success")
    end

    private

    def authorize
      authorize!(:create, ChangeZusatzsektionToFamily)
    end

    def change_zusatzsektion_to_family
      @change_zusatzsektion_to_family ||= ChangeZusatzsektionToFamily.new(role)
    end

    def role
      @role ||= Role.with_inactive.find(params[:role_id])
    end
  end
end
