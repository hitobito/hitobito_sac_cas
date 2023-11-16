# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

module SacCas::GroupResource
  extend ActiveSupport::Concern

  included do
    with_options writable: false do
      attribute :navision_id, :integer

      Group.subclasses.flat_map(&:mounted_attr_names).each do |attr|
        extra_attribute attr, :string do
          next if @object.class.mounted_attr_names.exclude?(attr)

          @object.send(attr)
        end
      end
    end
  end
end
