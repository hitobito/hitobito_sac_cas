# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module TableDisplays
  class Resolver
    ATTRS = {
      membership_years: :show,
      beitragskategorie: :show_full,
      antrag_fuer: :show,
      antragsdatum: :show,
      beitrittsdatum: :show,
      confirmed_at: :show_full,
      duplicate_exists: :show,
      wiedereintritt: :show,
      self_registration_reason: :show_full,
      address_valid: :show,
      sac_remark_national_office: :manage_national_office_remark,
      sac_remark_section_1: :manage_section_remarks,
      sac_remark_section_2: :manage_section_remarks,
      sac_remark_section_3: :manage_section_remarks,
      sac_remark_section_4: :manage_section_remarks,
      sac_remark_section_5: :manage_section_remarks
    }.freeze

    EXCLUSIONS_BY_GROUP = {
      antrag_fuer: [
        Group::SektionsNeuanmeldungenSektion,
        Group::SektionsNeuanmeldungenNv
      ],
      antragsdatum: [
        Group::SektionsNeuanmeldungenSektion,
        Group::SektionsNeuanmeldungenNv
      ]
    }.freeze

    def exclude_attr?
      excluded_remark? || exclude_by_group?
    end

    def initialize(template, person, attr)
      @template = template
      @person = person
      @attr = attr.to_sym
      @group = template&.parent
    end

    def label
      return PersonDuplicate.model_name.human if @attr == :duplicate_exists

      I18n.t("table_displays.person.#{@attr}", default: Person.human_attribute_name(@attr))
    end

    def to_s
      respond_to?(@attr, true) ? send(@attr) : @template.format_attr(@person, @attr)
    end

    private

    def excluded_remark?
      @template.cannot?(ATTRS.fetch(@attr), @person) if Person::SAC_REMARKS.include?(@attr.to_s)
    end

    def exclude_by_group?
      EXCLUSIONS_BY_GROUP[@attr]&.exclude?(@group.class)
    end

    def confirmed_at
      I18n.l(@person.confirmed_at.to_date) if @person.confirmed_at
    end

    def beitragskategorie
      @person.roles.collect(&:beitragskategorie).compact.sort.uniq.collect do |value|
        I18n.t(value, scope: "roles.beitragskategorie")
      end.join(", ").presence
    end

    def antrag_fuer
      if group_roles.any? { |r| SacCas::NEUANMELDUNG_ZUSATZSEKTION_ROLES.include?(r.class) }
        I18n.t("groups.sektion_secondary")
      elsif group_roles.any? { |r| SacCas::NEUANMELDUNG_STAMMSEKTION_ROLES.include?(r.class) }
        I18n.t("groups.sektion_primary")
      end
    end

    def beitrittsdatum
      convert_on = group_roles.collect(&:convert_on).min
      I18n.l(convert_on) if convert_on
    end

    def antragsdatum
      created_at = group_roles.collect(&:created_at).min
      I18n.l(created_at.to_date) if created_at
    end

    def duplicate_exists
      @template.f(@person.person_duplicates.reject(&:ignore).any?)
    end

    def wiedereintritt
      @template.f(!active_member? && previous_member?)
    end

    def address_valid
      @template.f(taggings_for(PersonTags::Validation::ADDRESS_INVALID).none?)
    end

    def newsletter
      @template.f(taggings_for(:newsletter).any?)
    end

    def taggings_for(name)
      ActsAsTaggableOn::Tagging.joins(:tag).where(taggable: @person, tags: {name: name})
    end

    def active_member?
      membership_roles.exists?
    end

    def previous_member?
      membership_roles.deleted.exists?
    end

    def membership_roles
      Role.where(type: SacCas::MITGLIED_STAMMSEKTION_ROLES,
        person_id: @person.id)
    end

    def group_roles
      @person.roles.select { |r| r.group_id == @group.id }
    end
  end
end
