#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::People::AlpsRecipientRow < Export::Tabular::Row
  attr_reader :reference_date, :abonnent_group_langs, :lang

  def initialize(entry, reference_date, abonnent_group_langs, lang: nil)
    super(entry)
    @reference_date = reference_date
    @abonnent_group_langs = abonnent_group_langs
    @lang = lang
  end

  def name
    entry.last_name.presence || entry.company_name
  end

  def amount
    1
  end

  def type
    mitglied? ? "Mitglied" : "Abonnent"
  end

  def company
    entry.company? ? "ja" : "nein"
  end

  def language
    return lang if lang

    if mitglied?
      entry.language
    else
      abonnent_group_langs.fetch(entry.alps_role_group_id)
    end
  end

  def entry_on
    if mitglied?
      role_start_on(SacCas::MITGLIED_ROLES)
    else
      role_start_on(SacCas::ABONNENT_MAGAZIN_ROLES)
    end
  end

  private

  def role_start_on(types)
    roles(types).min_by(&:start_on).start_on
  end

  def mitglied?
    Export::Tabular::People::AlpsRecipientsScope::MITGLIED_TYPES.include?(entry.alps_role_type)
  end

  def roles(types)
    entry.roles_unscoped.select { |role| types.include?(role.class) }
  end
end
