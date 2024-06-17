# Naming

Nachdem wir beim Projektstart eher auf deutsche Begriffe gesetzt haben, werden wir künftig hauptsächlich **englische** Begriffe im Code verwenden. Bestehender Code mit deutschen Terms müssen nicht umgestellt werden.

In Ausnahmefällen kann es sinnvoll sein einen deutschen Begriff zu verwenden, z.B. Beitragskategorie.

Bitte updated den Glossar hier damit wir Fachbegriffe immer gleich übersetzen.

Happy Naming!

## sac Prefix

Einen sac-Prefix kann man z.B. bei SAC spezifischen Attributen verwenden. Es gibt z.B. auf der Person ein Attribut `sac_family_main_person`. Der Begriff Family wird zum Teil auch im Core oder Youth Wagon verwendet, so ist auf ein Blick klar das es sich um eine SAC spezifische Erweiterung/Konzept handelt.

## Glossar

| SAC Begriff DE            | Technische Bezeichnung         | Ausnahmen                                     |
|---------------------------|--------------------------------|-----------------------------------------------|
| **Beitragskategorie**     | Beitragskategorie              |                                               |
| Einzel                    | adult                          |                                               |
| Familie                   | family                         |                                               |
| Jugend                    | youth                          |                                               |
|                           |                                |                                               |
| **Gruppen**               |                                |                                               |
| Sektion                   | sac_section                    | Group::Sektion                                |
| Ortsgruppe                |                                | Group::Ortsgruppe                             |
|                           |                                |                                               |
|                           |                                |                                               |
| **Mitgliedschaft**        |                                |                                               |
| Ehrenmitglied             | honorary_member                | Group::Sektion::Ehrenmitglied                 |
| Begünstigt                | benefited_member               | Group::Sektion::Beguenstigt                   |
| Hüttensolidaritätsbeitrag | hut_solidarity_fee             |                                               |
| Zentralverbandsbeitrag    | sac_fee                        |                                               |
| Eintrittsgebühr           | entry_fee                      |                                               |
|                           |                                |                                               |
| **Kurse/Touren**          |                                |                                               |
| Tourenleiter*in           | tour_guide, sac_tour_guide     | Group::SektionsTourenkommission::Tourenleiter |
