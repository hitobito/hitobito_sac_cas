# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

unless SelfRegistrationReason.exists?
  SelfRegistrationReason.seed_once(:id,
    {id: 1},
    {id: 2},
    {id: 3},
    {id: 4},
    {id: 5},
    {id: 6},
    {id: 7},
    {id: 8},
    {id: 9},
    {id: 10})

  SelfRegistrationReason::Translation.seed_once(:self_registration_reason_id, :locale,
    {self_registration_reason_id: 1, locale: "de", text: "Weil mich die Bergwelt fasziniert."},
    {self_registration_reason_id: 2, locale: "de", text: "Weil der SAC eine gute Sache ist."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 3, locale: "de", text: "Weil ich das Umweltengagement des SAC unterstütze."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 4, locale: "de", text: "Weil ich mich gerne mit Gleichgesinnten in den Bergen bewege."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 5, locale: "de", text: "Weil jemand aus meinem Bekanntenkreis Mitglied ist."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 6, locale: "de", text: "Wegen dem Tourenangebot in den Sektionen."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 7, locale: "de", text: "Wegen den vergünstigten Übernachtungen in den SAC-Hütten."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 8, locale: "de", text: "Wegen den vergünstigten Angeboten (SAC-Führer, SAC-Tourenportal, Club-Shop, etc.)."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 9, locale: "de", text: "Wegen den Ausbildungsmöglichkeiten."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 10, locale: "de", text: "Weil mich die Zeitschrift «Die Alpen» interessiert."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 1, locale: "fr", text: "Parce que le monde de la montagne me fascine."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 2, locale: "fr", text: "Parce que le CAS est une bonne chose."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 3, locale: "fr", text: "Parce que je soutiens l'engagement du CAS pour l'environnement."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 4, locale: "fr", text: "Parce que j'aime aller en montagne avec des gens qui partagent les mêmes idées que moi."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 5, locale: "fr", text: "Par suggestion d'ami(e)s et collègues."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 6, locale: "fr", text: "En raison de l'offre de courses dans les sections."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 7, locale: "fr", text: "En raison des rabais pour les nuitées dans les cabanes du CAS."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 8, locale: "fr", text: "En raison des offres forfaitaires (guides du CAS, portail des courses, Club Shop, etc.)."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 9, locale: "fr", text: "En raison des possibilités de formation."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 10, locale: "fr", text: "En raison de l'intérêt que je porte à la revue «Les Alpes»."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 1, locale: "it", text: "Perché sono affascinato dalla montagna."},
    {self_registration_reason_id: 2, locale: "it", text: "Perché il CAS è un'ottima cosa."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 3, locale: "it", text: "Perché sostengo l'impegno del CAS per l'ambiente."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 4, locale: "it", text: "Perché mi piace andare in montagna con gente che condivide i miei stessi principi."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 5, locale: "it", text: "Perché vi aderiscono persone che conosco."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 6, locale: "it", text: "A causa delle proposte di gite nelle sezioni."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 7, locale: "it", text: "Per il pernottamento vantaggioso nelle capanne del CAS."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 8, locale: "it", text: "Per le offerte vantaggiose (guide, portale escursionistico, Club Shop, etc.)."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 9, locale: "it", text: "Per le opportunità di formazione."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 10, locale: "it", text: "Perché mi interessa la rivista «Le Alpi»."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 1, locale: "en", text: "Because I'm fascinated by mountains."},
    {self_registration_reason_id: 2, locale: "en", text: "Because the SAC is a good thing."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 3, locale: "en", text: "Because I support the environmental engagement of the SAC."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 4, locale: "en", text: "Because I like spending time in the mountains with people who share the same interests as me."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 5, locale: "en", text: "Because somebody I know is already a member."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 6, locale: "en", text: "Because of the outings organised by the different sections."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 7, locale: "en", text: "Because I'd like to benefit from special rates in the SAC huts."},
    # rubocop:enable Layout/LineLength
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 8, locale: "en", text: "Because I'd like to benefit from other special rates (guide books, SAC Route Portal, online shop, etc.)."},
    # rubocop:enable Layout/LineLength
    {self_registration_reason_id: 9, locale: "en", text: "Because of the training offers."},
    # rubocop:todo Layout/LineLength
    {self_registration_reason_id: 10, locale: "en", text: "Because I'm interest in the magazine «Die Alpen»."})
  # rubocop:enable Layout/LineLength
end
