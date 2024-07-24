# Naming

Nachdem wir beim Projektstart eher auf deutsche Begriffe gesetzt haben, werden wir künftig
hauptsächlich **englische** Begriffe im Code verwenden. Bestehender Code mit deutschen Terms müssen
nicht umgestellt werden.

In Ausnahmefällen kann es sinnvoll sein einen deutschen Begriff zu verwenden, z.B.
Beitragskategorie.

Der Konsistenz halber werden Gruppen- und Rollentypen aktuell immer auf deutsch geschrieben, weil
eine Migration zu aufwändig wäre und weil dies ein breaking Change in der API und OIDC bedeuten
würde.

Bitte updated den Glossar hier damit wir Fachbegriffe immer gleich übersetzen.

Happy Naming!

## sac Prefix

Einen sac-Prefix kann man z.B. bei SAC spezifischen Attributen verwenden. Es gibt z.B. auf der
Person ein Attribut `sac_family_main_person`. Der Begriff Family wird zum Teil auch im Core oder
Youth Wagon verwendet, so ist auf ein Blick klar das es sich um eine SAC spezifische
Erweiterung/Konzept handelt.

## Glossar

| SAC Begriff DE               | Technische Bezeichnung     | Ausnahmen                                   |
|------------------------------|----------------------------|---------------------------------------------|
| **Beitragskategorie**        | Beitragskategorie          |                                             |
| Einzel                       | adult                      |                                             |
| Familie                      | family                     |                                             |
| Jugend                       | youth                      |                                             |
|                              |                            |                                             |
| **Gruppen**                  |                            |                                             |
| Sektion                      | sac_section                | Group::Sektion                              |
| Ortsgruppe                   |                            | Group::Ortsgruppe                           |
| Geschäftsstelle              | national_office            | Group::Geschaeftsstelle                     |
| Zentralvorstand              | central_board              | Group::Zentralvorstand                      |
| Vorstand                     | board                      | Group::SektionsVorstand                     |
| Sektionsfunktionäre          | section functionaries      | Group::SektionsFunktionaere                 |
| Hüttenkommission             | hut commission             | Group::SektionsKommissionHuetten            |
| Kommission Umwelt und Kultur |                            | Group::SektionsKommissionUmweltUndKultur    |
| Tourenkommission             | tour commission            | Group::SektionsKommissionTouren             |
| Touren und Kurse             | tours and courses          | Group::SektionsTourenUndKurse               |
|                              |                            |                                             |
| **Personen**                 |                            |                                             |
| SAC Mitarbeiter*in           | sac_employee               |                                             |
| Funktionär*in                | functionary                |                                             |
|                              |                            |                                             |
| **Rollen**                   |                            |                                             |
| Sektionspräsident*in         | section_president          | Group::Sektion::**::Praesidium              |
| Mitgliederverwaltung         |                            | Group::**::Mitgliederverwaltung             |
| Kommissionsmitglied          | commission_member          |                                             |
| Hüttenfunktionär             | huts_functionary           |                                             |
| Hüttenobmann*frau            | hut_chairman               |                                             |
| Hüttenwart*in                | hut_warden                 | Group::**huette::Huettenwart                |
| Hüttenchef*in                | hut_chief                  | Group::**huette::Huettenchef                |
| Tourenfunktionär             | tour_functionary           |                                             |
| Tourenchef*in                |                            | Group::SektionsTourenUndKurse**::Tourenchef |
| Leserecht                    |                            | Group::**::Leserecht                        |
| Schreibrecht                 |                            | Group::**::Schreibrecht                     |
| Andere                       |                            | Group::**::Andere                           |
|                              |                            |                                             |
| **Mitgliedschaft**           |                            |                                             |
| Mitglied Hauptsektion        | member                     |                                             |
| Mitglied Zusatzsektion       | member_additional          |                                             |
| Ehrenmitglied                | honorary_member            | Group::Sektion::Ehrenmitglied               |
| Begünstigt                   | benefited_member           | Group::Sektion::Beguenstigt                 |
| Hüttensolidaritätsbeitrag    | hut_solidarity_fee         |                                             |
| Zentralverbandsbeitrag       | sac_fee                    |                                             |
| Eintrittsgebühr              | entry_fee                  |                                             |
|                              |                            |                                             |
| **Kurse/Touren**             |                            |                                             |
| Tourenleiter*in              | tour_guide, sac_tour_guide | Group::SektionsTourenUndKurse::Tourenleiter |
|                              |                            |                                             |
| **Abonnements und Angebote** |                            |                                             |
| Tourenportal                 |                            | SAC_tourenportal_subscriber                 |
| SAC Magazin                  |                            | magazin_subscriber                          |
