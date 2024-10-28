# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports::Roles
  module Nav22Shared
    def initialize(...)
      @groups_by_type_and_name = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = {} } }
      @groups_by_name = Hash.new { |h, k| h[k] = {} }
      Group.all.each do |group| # rubocop:disable Rails/FindEach
        @groups_by_type_and_name[group.class][group.parent_id][group.name] = group
        @groups_by_name[group.parent_id][group.name] = group
      end
      @sektion_or_ortsgruppe_by_name = Group.where(
        type: SacImports::Roles::ImporterBase::SECTION_OR_ORTSGRUPPE_GROUP_TYPE_NAMES
      ).all.index_by { |g| g.name.downcase }
      super
    end

    def group_hierarchy(row, anchor = Group.root)
      group_names = row.slice(:group_level1, :group_level2, :group_level3, :group_level4)
        .values.reverse.drop_while(&:nil?).reverse

      (anchor != Group.root) ? group_names.drop(1) : group_names
    end

    def group_hierarchy_to_s(...) = group_hierarchy(...).join(" > ")

    def find_anchor(row)
      return Group.root if row[:layer_type] == "SAC/CAS"

      sektion_or_ortsgruppe_by_name(row[:group_level1])
    end

    def find_group(row, *group_names, parent: Group.root)
      return unless parent && group_names.present?
      head, *tail = group_names

      group = load_or_create_group(parent, head, tail.empty?)

      return group if tail.blank?

      find_group(row, *tail, parent: group)
    end

    def load_or_create_group(parent, name, leaf)
      case [parent, name]
      in [Group::SacCas => parent, "Verbände & Organisationen" => name]
        find_or_create(Group::SacCasVerbaende, parent, name)
      in [Group::SacCasVerbaende => parent, String => name]
        type = leaf ? Group::SacCasVerband : Group::SacCasVerbaende
        find_or_create(type, parent, name)

      in [Group::SacCas => parent, "SAC Kommissionen" => name]
        find_or_create(Group::Kommission, parent, name)
      in [Group::Kommission => parent, String => name]
        find_or_create(Group::Kommission, parent, name)

      in [Group::SacCas => parent, "SAC Geschäftsleitung"]
        find_or_create(Group::Geschaeftsleitung, parent)

      in [Group::SacCas => parent, "SAC Geschäftsstelle"]
        find_or_create(Group::Geschaeftsstelle, parent)

      in [Group::SacCas => parent, "SAC Ehrenmitglieder" => name]
        find_or_create(Group::Ehrenmitglieder, parent, name)

      in [Group::SacCas => parent, "SAC Zentralvorstand"]
        find_or_create(Group::Zentralvorstand, parent)

      in [Group::SacCas => parent, "Privathütten"]
        find(Group::SacCasPrivathuetten, parent)

      in [Group::SacCas => parent, "SAC Kurskader"]
        find_or_create(Group::SacCasKurskader, parent)

      in [Group::SacCas => parent, "Sektionshütten"]
        find(Group::SacCasClubhuetten, parent)

      in [Group::Sektion | Group::Ortsgruppe => parent, "Sektionsfunktionäre"]
        find_or_create(Group::SektionsFunktionaere, parent)
      in [Group::SektionsFunktionaere => parent, "Touren und Kurse"]
        find_or_create(Group::SektionsTourenUndKurse, parent)
      in [Group::SektionsTourenUndKurse => parent, "Touren und Kurse Sommer" => name]
        find_or_create(Group::SektionsTourenUndKurseSommer, parent, name)
      in [Group::SektionsTourenUndKurse => parent, "Touren und Kurse Winter" => name]
        find_or_create(Group::SektionsTourenUndKurseWinter, parent, name)

      else
        find_group_by_name(parent, name)
      end
    end

    def find(type, parent, name = nil)
      @groups_by_type_and_name[type][parent.id][name] ||= type.where(
        {name: name, parent_id: parent.id}.compact
      ).first
    end

    def find_or_create(type, parent, name = nil)
      @groups_by_type_and_name[type][parent.id][name] ||= type.where(
        {name: name, parent_id: parent.id}.compact
      ).first_or_create!
    end

    def find_group_by_name(parent, name) = @groups_by_name.dig(parent.id, name)

    def sektion_or_ortsgruppe_by_name(name) = @sektion_or_ortsgruppe_by_name[name.downcase]
  end
end
