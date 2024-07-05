# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module People
  module Neuanmeldungen
    class HandlerController < ApplicationController
      helper_method :group, :handler, :count, :ids

      respond_to :js, only: [:new]

      class_attribute :handler_class
      class_attribute :permitted_attrs

      def new
        assign_attributes
      end

      def create
        assign_attributes
        handler.call
        redirect_to group_people_path(group_id: group), notice: success_notice
      end

      private

      def permitted_params
        params.permit(permitted_attrs)
      end

      def group
        @group ||= Group.find(permitted_params.require(:group_id))
      end

      def ids
        @ids ||= permitted_params.require(:ids).to_s
      end

      def people_ids
        ids.split(",").map(&:to_i)
      end

      def assign_attributes
        handler.attributes = attributes
      end

      def attributes
        {
          group: group,
          people_ids: people_ids,
          **permitted_params.except(:group_id, :ids, :locale).to_h.symbolize_keys
        }
      end

      def count
        people_ids.count
      end

      def handler
        @handler ||= handler_class.new
      end

      def success_notice
        prefix = handler.to_partial_path.gsub(%r{/\w+\z}, "")
        t("#{prefix}.create.success", count: count)
      end
    end
  end
end
