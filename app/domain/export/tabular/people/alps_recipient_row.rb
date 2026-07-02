#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 2
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Export::Tabular::People::AlpsRecipientRow < Export::Tabular::Row
  attr_reader :reference_date, :abonnent_group_langs

  def initialize(entry, reference_date, abonnent_group_langs)
    super(entry)
    @reference_date = reference_date
    @abonnent_group_langs = abonnent_group_langs
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
    if mitglied?
      entry.language
    else
      role = current_role(Export::Tabular::People::AlpsRecipientsScope::MAGAZIN_ABONNENTEN)
      abonnent_group_langs.fetch(role.group_id)
    end
  end

  def entry_on
    if mitglied?
      role_start_on(SacCas::MITGLIED_ROLES)
    else
      role_start_on(Export::Tabular::People::AlpsRecipientsScope::MAGAZIN_ABONNENTEN)
    end
  end

  private

  def role_start_on(types)
    roles(types).min_by(&:start_on).start_on
  end

  def mitglied?
    current_role(SacCas::MITGLIED_ROLES).present?
  end

  def current_role(types)
    @current_role ||= {}
    return @current_role[types] if @current_role.key?(types)

    @current_role[types] =
      roles(types).find { |role| role.active?(reference_date) }
  end

  def roles(types)
    roles ||= {}
    roles[types] ||=
      entry
        .roles_unscoped
        .select { |role| types.include?(role.class) }
  end
end
