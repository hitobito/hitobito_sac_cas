# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#

##### Kostenstellen / NAV_10
def seed_cost_centers
  CostCenter.seed_once(:code,
    {code: "2100001"},
    {code: "2100022"},
    {code: "2100023"},
    {code: "2100024"},
    {code: "2100025"},
    {code: "2100026"},
    {code: "2100027"},
    {code: "2100028"},
    {code: "2100040"},
    {code: "2100050"},
    {code: "3200111"},
    {code: "3200310"})

  cost_centers = CostCenter.pluck(:code, :id).to_h
  CostCenter::Translation.seed_once(:cost_center_id, :locale,
    {cost_center_id: cost_centers.fetch("2100001"), locale: "de", label: "Breitensport"},
    {cost_center_id: cost_centers.fetch("2100022"), locale: "de", label: "Basiskurse"},
    {cost_center_id: cost_centers.fetch("2100023"), locale: "de", label: "Anwendungstouren"},
    {cost_center_id: cost_centers.fetch("2100024"), locale: "de", label: "J&S Kurse"},
    {cost_center_id: cost_centers.fetch("2100025"), locale: "de", label: "SAC Tourenleiterkurse"},
    {cost_center_id: cost_centers.fetch("2100026"), locale: "de", label: "Umweltkurse"},
    {cost_center_id: cost_centers.fetch("2100027"), locale: "de", label: "Hüttenkurse"},
    {cost_center_id: cost_centers.fetch("2100028"), locale: "de", label: "Sektionskurse"},
    {cost_center_id: cost_centers.fetch("2100040"), locale: "de", label: "Jugend"},
    {cost_center_id: cost_centers.fetch("2100050"), locale: "de", label: "SwissBolt"},
    {cost_center_id: cost_centers.fetch("3200111"), locale: "de", label: "Ski Mountaineering Nachwuchs"},
    {cost_center_id: cost_centers.fetch("3200310"), locale: "de", label: "Leistungsbergsteigen Exped Team"})
end

###### Kostenträger / NAV_11
def seed_cost_units
  CostUnit.seed_once(:code,
    {code: "A0100"},
    {code: "A0300"},
    {code: "A0500"},
    {code: "A0700"},
    {code: "A0900"},
    {code: "A1100"},
    {code: "A1300"},
    {code: "A1500"},
    {code: "A2000"},
    {code: "A2300"},
    {code: "A2500"},
    {code: "A5000"},
    {code: "A5200"},
    {code: "A5300"},
    {code: "A5400"},
    {code: "A5500"},
    {code: "A5600"},
    {code: "A6000"},
    {code: "A6500"},
    {code: "A6800"},
    {code: "A7000"},
    {code: "A7200"},
    {code: "A7300"},
    {code: "A7400"},
    {code: "A8000"},
    {code: "A8500"},
    {code: "A9000"},
    {code: "A9100"},
    {code: "A9500"})

  cost_units = CostUnit.pluck(:code, :id).to_h
  CostUnit::Translation.seed_once(:cost_unit_id, :locale,
    {cost_unit_id: cost_units.fetch("A0100"), locale: "de", label: "Skitechnik"},
    {cost_unit_id: cost_units.fetch("A0300"), locale: "de", label: "Skitouren"},
    {cost_unit_id: cost_units.fetch("A0500"), locale: "de", label: "Lawinen"},
    {cost_unit_id: cost_units.fetch("A0700"), locale: "de", label: "Snowboard"},
    {cost_unit_id: cost_units.fetch("A0900"), locale: "de", label: "Schneeschuhe"},
    {cost_unit_id: cost_units.fetch("A1100"), locale: "de", label: "Eisklettern"},
    {cost_unit_id: cost_units.fetch("A1300"), locale: "de", label: "Diverse Kurse Winter"},
    {cost_unit_id: cost_units.fetch("A1500"), locale: "de", label: "SAC - Leiterausbildung Winter"},
    {cost_unit_id: cost_units.fetch("A2000"), locale: "de", label: "SAC - Leiterfortbildung Winter"},
    {cost_unit_id: cost_units.fetch("A2300"), locale: "de", label: "J+S Leiterausbildung Winter"},
    {cost_unit_id: cost_units.fetch("A2500"), locale: "de", label: "J+S Leiterfortbildung Winter"},
    {cost_unit_id: cost_units.fetch("A5000"), locale: "de", label: "Fels und Eis"},
    {cost_unit_id: cost_units.fetch("A5200"), locale: "de", label: "Sportklettern"},
    {cost_unit_id: cost_units.fetch("A5300"), locale: "de", label: "Bergwandern"},
    {cost_unit_id: cost_units.fetch("A5400"), locale: "de", label: "Alpinwandern"},
    {cost_unit_id: cost_units.fetch("A5500"), locale: "de", label: "Mountainbike"},
    {cost_unit_id: cost_units.fetch("A5600"), locale: "de", label: "Diverse Kurse Sommer"},
    {cost_unit_id: cost_units.fetch("A6000"), locale: "de", label: "SAC - Leiterausbildung Sommer"},
    {cost_unit_id: cost_units.fetch("A6500"), locale: "de", label: "SAC - Leiterfortbildung Sommer"},
    {cost_unit_id: cost_units.fetch("A6800"), locale: "de", label: "J+S Leiterausbildung Sommer"},
    {cost_unit_id: cost_units.fetch("A7000"), locale: "de", label: "J+S Leiterfortbildung Sommer"},
    {cost_unit_id: cost_units.fetch("A7200"), locale: "de", label: "SAC - Lager Kinder- und Familienbergsteigen"},
    {cost_unit_id: cost_units.fetch("A7300"), locale: "de", label: "SAC - Jugend"},
    {cost_unit_id: cost_units.fetch("A7400"), locale: "de", label: "SAC - Leistungssport"},
    {cost_unit_id: cost_units.fetch("A8000"), locale: "de", label: "SAC - Tourenangebote Winter"},
    {cost_unit_id: cost_units.fetch("A8500"), locale: "de", label: "SAC - Tourenangebote Sommer"},
    {cost_unit_id: cost_units.fetch("A9000"), locale: "de", label: "SAC - Hüttenwartsausbildung"},
    {cost_unit_id: cost_units.fetch("A9100"), locale: "de", label: "SAC - Kurskaderausbildung"},
    {cost_unit_id: cost_units.fetch("A9500"), locale: "de", label: "SAC - Sektionen"})
end

##### Kurskategorien (NAV 13)
def seed_event_kind_categories
  cost_centers = CostCenter.pluck(:code, :id).to_h
  cost_units = CostUnit.pluck(:code, :id).to_h
  Event::KindCategory.seed_once(:order,
    {order: 5400, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A5400")},
    {order: 5300, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A5300")},
    {order: 5600, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A5600")},
    {order: 1300, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A1300")},
    {order: 1100, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A1100")},
    {order: 5000, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A5000")},
    {order: 6800, cost_center_id: cost_centers.fetch("2100024"), cost_unit_id: cost_units.fetch("A6800")},
    {order: 2300, cost_center_id: cost_centers.fetch("2100024"), cost_unit_id: cost_units.fetch("A2300")},
    {order: 7000, cost_center_id: cost_centers.fetch("2100024"), cost_unit_id: cost_units.fetch("A7000")},
    {order: 2500, cost_center_id: cost_centers.fetch("2100024"), cost_unit_id: cost_units.fetch("A2500")},
    {order: 500, cost_center_id: cost_centers.fetch("2100025"), cost_unit_id: cost_units.fetch("A0500")},
    {order: 5500, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A5500")},
    {order: 9000, cost_center_id: cost_centers.fetch("2100027"), cost_unit_id: cost_units.fetch("A9000")},
    {order: 7300, cost_center_id: cost_centers.fetch("2100040"), cost_unit_id: cost_units.fetch("A7300")},
    {order: 9100, cost_center_id: cost_centers.fetch("2100001"), cost_unit_id: cost_units.fetch("A9100")},
    {order: 7200, cost_center_id: cost_centers.fetch("2100040"), cost_unit_id: cost_units.fetch("A7200")},
    {order: 7400, cost_center_id: cost_centers.fetch("3200310"), cost_unit_id: cost_units.fetch("A7400")},
    {order: 6000, cost_center_id: cost_centers.fetch("2100025"), cost_unit_id: cost_units.fetch("A6000")},
    {order: 1500, cost_center_id: cost_centers.fetch("2100025"), cost_unit_id: cost_units.fetch("A1500")},
    {order: 6500, cost_center_id: cost_centers.fetch("2100025"), cost_unit_id: cost_units.fetch("A6500")},
    {order: 2000, cost_center_id: cost_centers.fetch("2100025"), cost_unit_id: cost_units.fetch("A2000")},
    {order: 8500, cost_center_id: cost_centers.fetch("2100023"), cost_unit_id: cost_units.fetch("A8500")},
    {order: 8000, cost_center_id: cost_centers.fetch("2100023"), cost_unit_id: cost_units.fetch("A8000")},
    {order: 900, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A0900")},
    {order: 9500, cost_center_id: cost_centers.fetch("2100028"), cost_unit_id: cost_units.fetch("A9500")},
    {order: 100, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A0100")},
    {order: 300, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A0300")},
    {order: 700, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A0700")},
    {order: 5200, cost_center_id: cost_centers.fetch("2100022"), cost_unit_id: cost_units.fetch("A5200")})

  kind_categories = Event::KindCategory.pluck(:order, :id).to_h
  Event::KindCategory::Translation.seed_once(:event_kind_category_id, :locale,
    {event_kind_category_id: kind_categories.fetch(5400), locale: "de", label: "Alpinwandern"},
    {event_kind_category_id: kind_categories.fetch(5300), locale: "de", label: "Bergwandern"},
    {event_kind_category_id: kind_categories.fetch(5600), locale: "de", label: "Diverse Kurse Sommer"},
    {event_kind_category_id: kind_categories.fetch(1300), locale: "de", label: "Diverse Kurse Winter"},
    {event_kind_category_id: kind_categories.fetch(1100), locale: "de", label: "Eisklettern"},
    {event_kind_category_id: kind_categories.fetch(5000), locale: "de", label: "Fels und Eis"},
    {event_kind_category_id: kind_categories.fetch(6800), locale: "de", label: "J+S Leiterausbildung Sommer"},
    {event_kind_category_id: kind_categories.fetch(2300), locale: "de", label: "J+S Leiterausbildung Winter"},
    {event_kind_category_id: kind_categories.fetch(7000), locale: "de", label: "J+S Leiterfortbildung Sommer"},
    {event_kind_category_id: kind_categories.fetch(2500), locale: "de", label: "J+S Leiterfortbildung Winter"},
    {event_kind_category_id: kind_categories.fetch(500), locale: "de", label: "Lawinen"},
    {event_kind_category_id: kind_categories.fetch(5500), locale: "de", label: "Mountainbike"},
    {event_kind_category_id: kind_categories.fetch(9000), locale: "de", label: "SAC - Hüttenwartsausbildung"},
    {event_kind_category_id: kind_categories.fetch(7300), locale: "de", label: "SAC - Jugend"},
    {event_kind_category_id: kind_categories.fetch(9100), locale: "de", label: "SAC - Kurskaderausbildung"},
    {event_kind_category_id: kind_categories.fetch(7200), locale: "de", label: "SAC - Lager Kinder- und Familienbergsteigen"},
    {event_kind_category_id: kind_categories.fetch(7400), locale: "de", label: "SAC - Leistungssport"},
    {event_kind_category_id: kind_categories.fetch(6000), locale: "de", label: "SAC - Leiterausbildung Sommer"},
    {event_kind_category_id: kind_categories.fetch(1500), locale: "de", label: "SAC - Leiterausbildung Winter"},
    {event_kind_category_id: kind_categories.fetch(6500), locale: "de", label: "SAC - Leiterfortbildung Sommer"},
    {event_kind_category_id: kind_categories.fetch(2000), locale: "de", label: "SAC - Leiterfortbildung Winter"},
    {event_kind_category_id: kind_categories.fetch(8500), locale: "de", label: "SAC - Tourenangebote Sommer"},
    {event_kind_category_id: kind_categories.fetch(8000), locale: "de", label: "SAC - Tourenangebote Winter"},
    {event_kind_category_id: kind_categories.fetch(900), locale: "de", label: "Schneeschuhe"},
    {event_kind_category_id: kind_categories.fetch(9500), locale: "de", label: "Sektionen - Angebote"},
    {event_kind_category_id: kind_categories.fetch(100), locale: "de", label: "Skitechnik"},
    {event_kind_category_id: kind_categories.fetch(300), locale: "de", label: "Skitouren"},
    {event_kind_category_id: kind_categories.fetch(700), locale: "de", label: "Snowboard"},
    {event_kind_category_id: kind_categories.fetch(5200), locale: "de", label: "Sportklettern"})
end

##### Kursstufen NAV 14
def seed_event_levels
  Event::Level.seed_once(:code,
    {code: 1, difficulty: 1},
    {code: 2, difficulty: 2},
    {code: 3, difficulty: 3},
    {code: 4, difficulty: 1},
    {code: 5, difficulty: 2},
    {code: 6, difficulty: 1},
    {code: 7, difficulty: 2},
    {code: 8, difficulty: 1},
    {code: 9, difficulty: 2})

  levels = Event::Level.pluck(:code, :id).to_h
  Event::Level::Translation.seed_once(:event_level_id, :locale,
    {event_level_id: levels.fetch(6), locale: "de", label: "J+S-Leiterausbildung", description: "J+S-Leiterkurse bringen dir mehr Wissen und Erfahrung, damit du auch Verantwortung übernehmen und selbstständig J+S-Gruppen führen kannst. In diesen Kursen wird das Können der Kursteilnehmenden überprüft."},
    {event_level_id: levels.fetch(7), locale: "de", label: "J+S-Leiterfortbildung", description: "J+S-Fortbildungsmodule bringen dich weiter und du verlängerst zugleich deine J+S-Leiteranerkennung."},
    {event_level_id: levels.fetch(1), locale: "de", label: "SAC-Einführungskurs", description: "SAC-Einführungskurse ermöglichen das Schnuppern von Bergluft und erste Erlebnisse in Fels, Schnee und Eis. Es sind keine Vorkenntnisse notwendig, der Bergführer zeigt dir alles von Grund auf. Du bist danach bestens auf die Teilnahme an einfachen Sektionstouren vorbereitet."},
    {event_level_id: levels.fetch(3), locale: "de", label: "SAC-Fortbildungskurs", description: "SAC-Fortbildungskurse bieten Gelegenheit, dein bisheriges Know-how im Bergsport zu vertiefen. Du gewinnst an Selbstständigkeit und Sicherheit. Du beherrschst die alpinen Grundkenntnisse und kannst eine solide Tourenpraxis aufweisen. Diese hast du z.?B. in einem SAC-Grundausbildungskurs und danach auf privaten und SAC-Sektionstouren erworben. Mittelschwere private oder anspruchsvolle Touren mit der Sektion sind anschliessend kein Problem mehr."},
    {event_level_id: levels.fetch(2), locale: "de", label: "SAC-Grundausbildungskurs", description: "In SAC-Grundausbildungskursen verbesserst du deine Kenntnisse in der gewählten Bergsportart. Erste Erfahrungen in der jeweiligen Disziplin sind deshalb erforderlich. Diese hast du z. B. in einem SAC-Einführungskurs und danach auf SAC-Sektionstouren erworben. Routinierte Bergführerinnen fördern deine Selbstständigkeit in der Planung und Durchführung von Bergtouren. Einfachere private oder mittelschwere Touren mit der Sektion sind anschliessend kein Problem mehr."},
    {event_level_id: levels.fetch(4), locale: "de", label: "SAC-Leiterausbildung", description: "SAC-Tourenleiterkurse ermöglichen dir den Erwerb und Ausbau von Führungskompetenz, welche du unter anderem für das künftige Leiten von SAC-Sektionstouren benötigst. Erfahrung als Seilschaftsführer auf selbstständig durchgeführten Touren (mit dem Niveau der erwähnten Vergleichstouren) ist unerlässlich. In diesen Kursen wird das Können der Kursteilnehmenden überprüft."},
    {event_level_id: levels.fetch(5), locale: "de", label: "SAC-Leiterfortbildung", description: "Verschiedene SAC-Tourenleiterfortbildungskurse ermöglichen dir, dich als aktive SAC-Tourenleiterin weiterzubilden und der Fortbildungspflicht nachzukommen."},
    {event_level_id: levels.fetch(8), locale: "de", label: "SAC-Tour - Stufe leicht", description: "Bei den SAC-Anwendungstouren mit Schwierigkeitsgrad «leicht» erwarten dich technisch leichte Touren von ca. 500 – 1000 Höhenmeter und einer Gehzeit von 4 – 6 Stunden. Vorzugsweise bringst du etwas Tourenerfahrung in der jeweiligen Disziplin mit oder hast schon einen Einführungskurs in der entsprechenden Disziplin besucht. Wenn du dich bei einem Tempo von 250 Hm pro Stunde wohl fühlst, kannst du die Touren noch mehr geniessen. Während der Touren festigst du die technischen und sicherheitsrelevanten Basics in der jeweiligen Disziplin und wendest diese laufend an. Anwendungstouren «leicht» sind eine gute Grundlage oder Vorbereitung für die Teilnahme an einem Grundkurs."},
    {event_level_id: levels.fetch(9), locale: "de", label: "SAC-Tour - Stufe mittelschwer", description: "Bei den SAC-Anwendungstouren mit Schwierigkeitsgrad «mittel-schwer» erwarten dich technisch mittelschwere Touren von 800 – 1200 Höhenmeter und einer Gehzeit von 5 – 7 Stunden. Du bringst Tourenerfahrung in der jeweiligen Disziplin mit oder hast schon einen Grundkurs in der entsprechenden Disziplin besucht. Wenn du dich bei einem Tempo von 300 Hm pro Stunde wohl fühlst, kannst du die Touren noch mehr geniessen. Während der Touren festigst du Techniken und Wissen, die auf der Grundstufe vermittelt werden. Anwendungstouren «mittel-schwer» sind eine gute Grundlage oder Vorbereitung für die Teilnahme an einem Fortbildungskurs."},
    {event_level_id: levels.fetch(6), locale: "fr", label: "Formation de moniteur J+S", description: "Les cours de formation de moniteur J+S t’apportent plus de connaissances et d’expériences afin que tu puisses aussi assumer des responsabilités et conduire des groupes J+S de manière autonome. Dans ces cours, les compétences des participant(e)s seront contrôlées."},
    {event_level_id: levels.fetch(7), locale: "fr", label: "Perfectionnement de moniteur J+S", description: "Les modules de perfectionnement te permettent de progresser tout en prolongeant la reconnaissance de ton diplôme de moniteur J+S."},
    {event_level_id: levels.fetch(1), locale: "fr", label: "Cours d'introduction du CAS", description: "Les cours d’introduction du CAS permettent de respirer l’air des montagnes et d’acquérir les premières expériences sur rocher, neige et glace. Aucune connaissance préalable n’est nécessaire, le guide de montagne t’enseigne tout depuis la base. Tu seras ensuite prêt à participer de manière optimale aux courses de section faciles."},
    {event_level_id: levels.fetch(3), locale: "fr", label: "Cours de perfectionnement du CAS", description: "Les cours de perfectionnement offrent la possibilité d’approfondir tes acquis dans les sports de montagne. Ils te permettent de renforcer ton autonomie et ton assurance. Tu maîtrises les connaissances alpines de base et bénéficies d’une expérience solide des courses. Tu les auras par exemple acquises lors d’un cours de formation de base du CAS, puis en effectuant des courses privées ou de section. Les courses privées de niveau moyen ou les courses de section exigeantes ne te poseront ensuite plus aucun problème."},
    {event_level_id: levels.fetch(2), locale: "fr", label: "Cours de formation de base du CAS", description: "Les cours de formation de base du CAS te permettent d’approfondir tes connaissances dans le sport de montagne de ton choix. Des premières expériences sont dès lors nécessaires. Tu les auras par exemple acquises lors d’un cours d’introduction du CAS, puis en participant aux courses de section du CAS. Des guides de montagne expérimentés mettent ton autonomie à l’épreuve dans la planification et la réalisation de courses en montagne. Les courses privées faciles et celles de difficulté moyenne avec la section ne te poseront ensuite plus aucun problème."},
    {event_level_id: levels.fetch(4), locale: "fr", label: "Formation de moniteur du CAS", description: "Les cours de formation de moniteur du CAS te permettent d’acquérir et d’élargir les compétences de direction dont tu devras faire preuve lorsque tu conduiras des courses de section du CAS. Une expérience en tant que chef de cordée lors de courses individuelles (comparables aux courses de référence mentionnées) est indispensable. Dans ces cours, les compétences des participant(e)s seront contrôlées."},
    {event_level_id: levels.fetch(5), locale: "fr", label: "Perfectionnement de moniteur du CAS", description: "Plusieurs cours de perfectionnement des moniteurs du CAS te permettent de te perfectionner en tant que chef de courses actif du CAS afin de satisfaire à l’obligation de perfectionnement."},
    {event_level_id: levels.fetch(8), locale: "fr", label: "Courses CAS - Niveau faciles", description: "L’offre des courses « faciles » proposée par le CAS comprend des courses techniquement faciles comptant entre 4 et 6 heures de temps de marche et dont le dénivelé est compris entre env. 500 et 1000 mètres. Il est préférable de disposer d’une certaine expérience ou d’avoir déjà suivi un cours d’introduction dans la discipline choisie. Si tu te sens à l’aise avec un rythme de 250 mètres de dénivelé par heure, tu profiteras encore plus de la course. Durant les courses, tu consolideras les bases techniques et de sécurité dans la discipline choisie et tu les appliqueras en permanence. Les courses d'application « faciles » constituent une bonne base ou préparation pour participer à un cours de base."},
    {event_level_id: levels.fetch(9), locale: "fr", label: "Courses CAS - Niveau moeynnes", description: "Les courses « moyennes » du CAS présentent des difficultés techniques moyennes, un dénivelé de 800 à 1200 mètres et un temps de marche de 5 à 7 heures. Tu disposes d’expérience et tu as déjà suivi un cours de base dans la discipline choisie. Si tu te sens capable de tenir un rythme de 300 mètres de dénivelé par heure, tu profiteras encore plus de la course. Durant les courses tu consolideras les techniques et le savoir transmis dans la formation de base. Les courses d'application « moyennes » constituent une bonne base ou préparation pour participer à un cours de perfectionnement."})
end

def seed_course_compensation_categories
  CourseCompensationCategory.seed_once(:short_name,
    {short_name: "HO-0001", kind: :day, description: "Tageshonorar Bergführer"},
    {short_name: "HO-0002", kind: :day, description: "Tageshonorar Bergführer Aspirant"},
    {short_name: "HO-0003", kind: :day, description: "Tageshonorar Kletterlehrer"},
    {short_name: "HO-0004", kind: :day, description: "Tageshonorar Wanderleiter"},
    {short_name: "HO-0007", kind: :day, description: "Tageshonorar Schneehschuhleiter"},
    {short_name: "HO-0008", kind: :day, description: "Tageshonorar Bike-Instruktor"},
    {short_name: "HO-0009", kind: :day, description: "Tageshonorar Arzt / Assistenzarzt"},
    {short_name: "HO-0011", kind: :day, description: "Tageshonorar Psychologe"},
    {short_name: "HO-0012", kind: :day, description: "Tageshonorar Meteorologe"},
    {short_name: "HON-KAT-I", kind: :day, description: "Tageshonorar/Kurskategorie I"},
    {short_name: "HON-KAT-II", kind: :day, description: "Tageshonorar/Kurskategorie II"},
    {short_name: "HON-KAT-III", kind: :day, description: "Tageshonorar/Kurskategorie III"},
    {short_name: "HON-KAT-IV", kind: :day, description: "Tageshonorar/Kurskategorie IV"},
    {short_name: "HON-KAT-V", kind: :day, description: "Tageshonorar/Kurskategorie V"},
    {short_name: "KP-ADMIN-KAT I-IV", kind: :flat, description: "Kurspauschale/Administration"},
    {short_name: "KP-REISE/MATERIAL", kind: :flat, description: "Kurspauschale/Reise und Material"},
    {short_name: "KV-0001", kind: :day, description: "Kursvorbereitung Kursleitung"},
    {short_name: "SPD-0001", kind: :flat, description: "Spesen Diverse"},
    {short_name: "SPÖ-0001", kind: :flat, description: "Spesen Öffentlicher Verkehr"},
    {short_name: "SPP-0001", kind: :flat, description: "Spesen Privatauto/Mietauto"},
    {short_name: "TP-SKI-TECHNIK/PASS", kind: :day, description: "Tagespauschale - Skipass/Skitechnikkurse"},
    {short_name: "UB-HUETTE", kind: :budget, description: "Budgetvorgabe für SAC Hütte"})

  categories = CourseCompensationCategory.pluck(:short_name, :id).to_h
  CourseCompensationCategory::Translation.seed_once(:course_compensation_category_id, :locale,
    {course_compensation_category_id: categories.fetch("HO-0001"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Bergführer", name_assistant_leader: "Tageshonorar – Klassenleitung/Bergführer"},
    {course_compensation_category_id: categories.fetch("HO-0002"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Bergführer Aspirant", name_assistant_leader: "Tageshonorar – Klassenleitung/Bergführer Aspirant"},
    {course_compensation_category_id: categories.fetch("HO-0003"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Kletterlehrer", name_assistant_leader: "Tageshonorar – Klassenleitung/Kletterlehrer"},
    {course_compensation_category_id: categories.fetch("HO-0004"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Wanderleiter", name_assistant_leader: "Tageshonorar – Klassenleitung/Wanderleiter"},
    {course_compensation_category_id: categories.fetch("HO-0007"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Schneeschuhleiter", name_assistant_leader: "Tageshonorar – Klassenleitung/Schneeschuhleiter"},
    {course_compensation_category_id: categories.fetch("HO-0008"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Bike-Instruktor", name_assistant_leader: "Tageshonorar – Klassenleitung/Bike-Instruktor"},
    {course_compensation_category_id: categories.fetch("HO-0009"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Arzt / Assistenzarzt", name_assistant_leader: "Tageshonorar – Klassenleitung/Arzt / Assistenzarzt"},
    {course_compensation_category_id: categories.fetch("HO-0011"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Psychologe", name_assistant_leader: "Tageshonorar – Klassenleitung/Psychologe"},
    {course_compensation_category_id: categories.fetch("HO-0012"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Meteorologe", name_assistant_leader: "Tageshonorar – Klassenleitung/Meteorologe"},
    {course_compensation_category_id: categories.fetch("HON-KAT-I"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Kurskategorie I", name_assistant_leader: "Tageshonorar – Klassenleitung/Kurskategorie I"},
    {course_compensation_category_id: categories.fetch("HON-KAT-II"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Kurskategorie II", name_assistant_leader: "Tageshonorar – Klassenleitung/Kurskategorie II"},
    {course_compensation_category_id: categories.fetch("HON-KAT-III"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Kurskategorie III", name_assistant_leader: "Tageshonorar – Klassenleitung/Kurskategorie III"},
    {course_compensation_category_id: categories.fetch("HON-KAT-IV"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Kurskategorie IV", name_assistant_leader: "Tageshonorar – Klassenleitung/Kurskategorie IV"},
    {course_compensation_category_id: categories.fetch("HON-KAT-V"), locale: "de", name_leader: "Tageshonorar – Kursleitung/Kurskategorie V", name_assistant_leader: "Tageshonorar – Klassenleitung/Kurskategorie V"},
    {course_compensation_category_id: categories.fetch("KP-ADMIN-KAT I-IV"), locale: "de", name_leader: "Kurspauschale – Kursleitung/Administration", name_assistant_leader: ""},
    {course_compensation_category_id: categories.fetch("KP-REISE/MATERIAL"), locale: "de", name_leader: "Kurspauschale – Kursleitung/Reise und Material", name_assistant_leader: "Kurspauschale – Klassenleitung/Reise und Material"},
    {course_compensation_category_id: categories.fetch("KV-0001"), locale: "de", name_leader: "Kursvorbereitung Kursleitung", name_assistant_leader: ""},
    {course_compensation_category_id: categories.fetch("SPD-0001"), locale: "de", name_leader: "Spesen Kursleitung – Diverse", name_assistant_leader: "Spesen Klassenleitung – Diverse"},
    {course_compensation_category_id: categories.fetch("SPÖ-0001"), locale: "de", name_leader: "Spesen – Kursleitung/Öffentlicher Verkehr", name_assistant_leader: "Spesen – Klassenleitung/Öffentlicher Verkehr"},
    {course_compensation_category_id: categories.fetch("SPP-0001"), locale: "de", name_leader: "Spesen – Kursleitung/Privatauto/Mietauto", name_assistant_leader: "Spesen – Klassenleitung/Privatauto/Mietauto"},
    {course_compensation_category_id: categories.fetch("TP-SKI-TECHNIK/PASS"), locale: "de", name_leader: "Tagespauschale – Kursleitung/Skipass/Skitechnikkurse", name_assistant_leader: "Tagespauschale – Klassenleitung/Skipass/Skitechnikkurse"},
    {course_compensation_category_id: categories.fetch("UB-HUETTE"), locale: "de", name_leader: "SAC Hütte", name_assistant_leader: "SAC Hütte"})
end

def seed_course_compensation_rates
  categories = CourseCompensationCategory.pluck(:short_name, :id).to_h
  CourseCompensationRate.seed_once(:course_compensation_category_id,
    {course_compensation_category_id: categories.fetch("HO-0001"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0002"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 440.00, rate_assistant_leader: 440.00},
    {course_compensation_category_id: categories.fetch("HO-0003"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0004"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0007"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0008"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0009"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0011"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HO-0012"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 530.00, rate_assistant_leader: 530.00},
    {course_compensation_category_id: categories.fetch("HON-KAT-I"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 550.00, rate_assistant_leader: 540.00},
    {course_compensation_category_id: categories.fetch("HON-KAT-II"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 470.00, rate_assistant_leader: 460.00},
    {course_compensation_category_id: categories.fetch("HON-KAT-III"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 570.00, rate_assistant_leader: 540.00},
    {course_compensation_category_id: categories.fetch("HON-KAT-IV"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 600.00, rate_assistant_leader: 560.00},
    {course_compensation_category_id: categories.fetch("HON-KAT-V"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 550.00, rate_assistant_leader: 540.00},
    {course_compensation_category_id: categories.fetch("KP-ADMIN-KAT I-IV"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 150.00, rate_assistant_leader: 0.00},
    {course_compensation_category_id: categories.fetch("KP-REISE/MATERIAL"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 130.00, rate_assistant_leader: 130.00},
    {course_compensation_category_id: categories.fetch("KV-0001"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 50.00, rate_assistant_leader: 0.00},
    {course_compensation_category_id: categories.fetch("SPD-0001"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 0.00, rate_assistant_leader: 0.00},
    {course_compensation_category_id: categories.fetch("SPÖ-0001"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 0.00, rate_assistant_leader: 0.00},
    {course_compensation_category_id: categories.fetch("SPP-0001"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 0.70, rate_assistant_leader: 0.70},
    {course_compensation_category_id: categories.fetch("TP-SKI-TECHNIK/PASS"), valid_from: "2024-01-01", valid_to: nil, rate_leader: 60.00, rate_assistant_leader: 60.00},
    {course_compensation_category_id: categories.fetch("UB-HUETTE"), valid_from: "2024-01-01", valid_to: "2024-12-31", rate_leader: 0.00, rate_assistant_leader: 0.00})
end

# once the integration environment is seeded, only seed when the database is empty
seed_cost_centers # unless CostCenter.exist?
seed_cost_units # unless CostUnit.exist?
seed_event_kind_categories # unless Event::KindCategory.exist?
seed_event_levels # unless Event::Level.exist?
seed_course_compensation_categories # unless CourseCompensationCategory.exist?
seed_course_compensation_rates # unless CourseCompensationRate.exist?
