# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

unless TerminationReason.exists?
  TerminationReason.seed_once(:id, (1..8).map { {id: _1} })

  TerminationReason::Translation.seed_once(:termination_reason_id, :locale,
    {termination_reason_id: 1, locale: "de", text: "Keine Angabe"},
    {termination_reason_id: 2, locale: "de", text: "Gestorben"},
    {termination_reason_id: 3, locale: "de", text: "Weil ich nicht mehr in den Bergen bin"},
    {termination_reason_id: 4, locale: "de", text: "Aus gesundheitlichen Gründen"},
    {termination_reason_id: 5, locale: "de", text: "Altersbedingt"},
    {termination_reason_id: 6, locale: "de", text: "Weil es zu teuer ist"},
    {termination_reason_id: 7, locale: "de", text: "Weil ich mich nicht mehr mit dem SAC identifizieren kann"},
    {termination_reason_id: 8, locale: "de", text: "Weitere"},
    {termination_reason_id: 1, locale: "fr", text: "Aucune indication"},
    {termination_reason_id: 2, locale: "fr", text: "Décédé*e"},
    {termination_reason_id: 3, locale: "fr", text: "Parce que je ne suis plus en montagne"},
    {termination_reason_id: 4, locale: "fr", text: "Pour des raisons de santé"},
    {termination_reason_id: 5, locale: "fr", text: "En raison de l’âge"},
    {termination_reason_id: 6, locale: "fr", text: "Parce que c’est trop cher"},
    {termination_reason_id: 7, locale: "fr", text: "Parce que je ne m’identifie plus au CAS"},
    {termination_reason_id: 8, locale: "fr", text: "Autres"},
    {termination_reason_id: 1, locale: "it", text: "Non specificato"},
    {termination_reason_id: 2, locale: "it", text: "Deceduto"},
    {termination_reason_id: 3, locale: "it", text: "Perché non vado piú in montagna"},
    {termination_reason_id: 4, locale: "it", text: "Per motivi di salute"},
    {termination_reason_id: 5, locale: "it", text: "Per motivi di età"},
    {termination_reason_id: 6, locale: "it", text: "Perché è troppo costoso"},
    {termination_reason_id: 7, locale: "it", text: "Perché non riesco piú a identificarmi nel CAS"},
    {termination_reason_id: 8, locale: "it", text: "Altri motivi"},
    {termination_reason_id: 1, locale: "en", text: "Not specified"},
    {termination_reason_id: 2, locale: "en", text: "Deceased"},
    {termination_reason_id: 3, locale: "en", text: "Because I'm no longer active in the mountains"},
    {termination_reason_id: 4, locale: "en", text: "For health reasons"},
    {termination_reason_id: 5, locale: "en", text: "For age reasons"},
    {termination_reason_id: 6, locale: "en", text: "Because it's too expensive"},
    {termination_reason_id: 7, locale: "en", text: "Because I can no longer relate to the SAC"},
    {termination_reason_id: 8, locale: "en", text: "Other"})
end
