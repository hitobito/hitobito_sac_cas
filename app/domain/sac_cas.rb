# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas
  MITGLIED_HAUPTSEKTION_ROLES = [
    ::Group::SektionsMitglieder::Mitglied,
    ::Group::SektionsNeuanmeldungenNv::Neuanmeldung,
    ::Group::SektionsNeuanmeldungenSektion::Neuanmeldung
  ].freeze

  MITGLIED_HAUPTSEKTION_ROLE_TYPES = MITGLIED_HAUPTSEKTION_ROLES.map(&:sti_name).freeze

  MITGLIED_ZUSATZSEKTION_ROLES = [
    ::Group::SektionsMitglieder::MitgliedZusatzsektion,
    ::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
    ::Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion
  ].freeze

  MITGLIED_ZUSATZSEKTION_ROLE_TYPES = MITGLIED_ZUSATZSEKTION_ROLES.map(&:sti_name).freeze

  MITGLIED_ROLES = (MITGLIED_HAUPTSEKTION_ROLES + MITGLIED_ZUSATZSEKTION_ROLES).freeze
  MITGLIED_ROLE_TYPES = MITGLIED_ROLES.map(&:sti_name).freeze
end
