# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::Group
  extend ActiveSupport::Concern

  included do
    # Define additional used attributes
    # self.used_attributes += [:website, :bank_account, :description]
    # self.superior_attributes = [:bank_account]

    root_types Group::SacCas

    alias_method :group_id, :id

    attribute :navision_id, :integer

    class << self
      def order_by_type
        joins("INNER JOIN group_type_orders ON group_type_orders.name = groups.type")
          .order("group_type_orders.order_weight ASC")
      end
    end
  end

  def navision_id_padded
    navision_id&.to_s&.rjust(8, "0")
  end

  def sektion_or_ortsgruppe?
    [Group::Sektion, Group::Ortsgruppe].any? { |c| is_a?(c) }
  end
end
