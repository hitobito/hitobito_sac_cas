# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas
  module FilterNavigation
    module Events
      private

      def init_dropdown_links
        add_tour_approval_filter_links if tour_list? && user_is_pruefer_in_layer?
        super
      end

      def add_tour_approval_filter_links
        add_approval_filter_item(:my_pending_approvals)
        add_approval_filter_item(:my_approval_responsibilities)
      end

      def add_approval_filter_item(key)
        name = translate(key)
        dropdown.add_item(name, tour_approval_filter_path(key, name))
      end

      def tour_approval_filter_path(filter_key, name)
        template.url_for(
          params.to_unsafe_h
            .merge(filters: {filter_key => {active: "1"}},
              range: "deep",
              name: name,
              only_path: true)
            .except(:returning)
        )
      end

      def tour_list?
        filter.event_type == ::Event::Tour
      end

      def user_is_pruefer_in_layer?
        ::Group::FreigabeKomitee::Pruefer
          .joins(:group)
          .where(person_id: template.current_user.id)
          .where(groups: {layer_group_id: group.layer_group.id})
          .exists?
      end
    end
  end
end
