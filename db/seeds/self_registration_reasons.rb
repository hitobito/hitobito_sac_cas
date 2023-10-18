# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

SelfRegistrationReason.seed_once(:id,
  { id: 1 },
  { id: 2 },
  { id: 3 },
  { id: 4 },
  { id: 5 },
  { id: 6 },
  { id: 7 },
  { id: 8 },
  { id: 9 },
  { id: 10 }
)

SelfRegistrationReason::Translation.seed_once(:self_registration_reason_id, :locale,
  { self_registration_reason_id: 1, locale: 'de', text: 'Weil mich die Bergwelt fasziniert.' },
  { self_registration_reason_id: 2, locale: 'de', text: 'Weil der SAC eine gute Sache ist.' },
  { self_registration_reason_id: 3, locale: 'de', text: 'Weil ich das Umweltengagement des SAC unterstütze.' },
  { self_registration_reason_id: 4, locale: 'de', text: 'Weil ich mich gerne mit Gleichgesinnten in den Bergen bewege.' },
  { self_registration_reason_id: 5, locale: 'de', text: 'Weil jemand aus meinem Bekanntenkreis Mitglied ist.' },
  { self_registration_reason_id: 6, locale: 'de', text: 'Wegen dem Tourenangebot in den Sektionen.' },
  { self_registration_reason_id: 7, locale: 'de', text: 'Wegen den vergünstigten Übernachtungen in den SAC-Hütten.' },
  { self_registration_reason_id: 8, locale: 'de', text: 'Wegen den vergünstigten Angeboten (SAC-Führer, SAC-Tourenportal, Club-Shop, etc.).' },
  { self_registration_reason_id: 9, locale: 'de', text: 'Wegen den Ausbildungsmöglichkeiten.' },
  { self_registration_reason_id: 10, locale: 'de', text: 'Weil mich die Zeitschrift «Die Alpen» interessiert.' },

  { self_registration_reason_id: 1, locale: 'fr', text: 'Parce que le monde de la montagne me fascine.' },
  { self_registration_reason_id: 2, locale: 'fr', text: 'Parce que le CAS est une bonne chose.' },
  { self_registration_reason_id: 3, locale: 'fr', text: 'Parce que je soutiens l\'engagement du CAS pour l\'environnement.' },
  { self_registration_reason_id: 4, locale: 'fr', text: 'Parce que j’aime aller en montagne avec des gens qui partagent les mêmes idées que moi.' },
  { self_registration_reason_id: 5, locale: 'fr', text: 'Par suggestion d\'ami(e)s et collègues.' },
  { self_registration_reason_id: 6, locale: 'fr', text: 'En raison de l\'offre de courses dans les sections.' },
  { self_registration_reason_id: 7, locale: 'fr', text: 'En raison des rabais pour les nuitées dans les cabanes du CAS.' },
  { self_registration_reason_id: 8, locale: 'fr', text: 'En raison des offres forfaitaires (guides du CAS, portail des courses, Club Shop, etc.).' },
  { self_registration_reason_id: 9, locale: 'fr', text: 'En raison des possibilités de formation.' },
  { self_registration_reason_id: 10, locale: 'fr', text: 'En raison de l\'intérêt que je porte à la revue «Les Alpes».' },

  { self_registration_reason_id: 1, locale: 'it', text: 'Perché sono affascinato dalla montagna.' },
  { self_registration_reason_id: 2, locale: 'it', text: 'Perché il CAS è un\'ottima cosa.' },
  { self_registration_reason_id: 3, locale: 'it', text: 'Perché sostengo l\'impegno del CAS per l\'ambiente.' },
  { self_registration_reason_id: 4, locale: 'it', text: 'Perché mi piace andare in montagna con gente che condivide i miei stessi principi.' },
  { self_registration_reason_id: 5, locale: 'it', text: 'Perché vi aderiscono persone che conosco.' },
  { self_registration_reason_id: 6, locale: 'it', text: 'A causa delle proposte di gite nelle sezioni.' },
  { self_registration_reason_id: 7, locale: 'it', text: 'Per il pernottamento vantaggioso nelle capanne del CAS.' },
  { self_registration_reason_id: 8, locale: 'it', text: 'Per le offerte vantaggiose (guide, portale escursionistico, Club Shop, etc.).' },
  { self_registration_reason_id: 9, locale: 'it', text: 'Per le opportunità di formazione.' },
  { self_registration_reason_id: 10, locale: 'it', text: 'Perché mi interessa la rivista «Le Alpi».' },

  { self_registration_reason_id: 1, locale: 'en', text: 'Because I’m fascinated by mountains.' },
  { self_registration_reason_id: 2, locale: 'en', text: 'Because the SAC is a good thing.' },
  { self_registration_reason_id: 3, locale: 'en', text: 'Because I support the environmental engagement of the SAC.' },
  { self_registration_reason_id: 4, locale: 'en', text: 'Because I like spending time in the mountains with people who share the same interests as me.' },
  { self_registration_reason_id: 5, locale: 'en', text: 'Because somebody I know is already a member.' },
  { self_registration_reason_id: 6, locale: 'en', text: 'Because of the outings organised by the different sections.' },
  { self_registration_reason_id: 7, locale: 'en', text: 'Because I\'d like to benefit from special rates in the SAC huts.' },
  { self_registration_reason_id: 8, locale: 'en', text: 'Because I\'d like to benefit from other special rates (guide books, SAC Route Portal, online shop, etc.).' },
  { self_registration_reason_id: 9, locale: 'en', text: 'Because of the training offers.' },
  { self_registration_reason_id: 10, locale: 'en', text: 'Because I’m interest in the magazine «Die Alpen».' }
)
