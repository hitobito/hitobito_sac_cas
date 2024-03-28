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

      Group.subclasses.flat_map(&:mounted_attr_names).uniq.each do |attr|
        extra_attribute attr, :string do
          next if @object.class.mounted_attr_names.exclude?(attr)

          @object.send(attr)
        end
      end
    end

    extra_attribute :has_youth_organization, :boolean do
      @object.decorate.has_youth_organization?
    end
    on_extra_attribute(:has_youth_organization) { |scope| scope.includes(:social_accounts) }

    extra_attribute :members_count, :integer, description: <<~DESCRIPTION do
      The number of `Mitglied` roles in the direct children of this group. It does not
      include roles nested deeper below (e.g. on a Sektion it counts only Sektionsmitglieder
      but not Ortsgruppenmitglieder)..
      Is `null` for all groups other than `Sektion` and `Ortsgruppe`.
    DESCRIPTION
      @object.decorate.members_count
    end
    on_extra_attribute(:members_count) { |scope| scope.includes(children: :roles) }

    extra_attribute :membership_admission_through_gs, :boolean, description: <<~DESCRIPTION do
      Membership applications are processed by the Geschäftsstelle.
    DESCRIPTION
      @object.decorate.membership_admission_through_gs?
    end
    on_extra_attribute(:membership_admission_through_gs) { |scope| scope.includes(:children) }

    extra_attribute :membership_self_registration_url, :string do
      @object.decorate.membership_self_registration_url
    end
    on_extra_attribute(:membership_self_registration_url) { |scope| scope.includes(:children) }

  end
end
