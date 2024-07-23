# SAC/CAS specific imports

```txt
oc rsync tmp/xlsx delayed-job-db8bb7688-c6nrn-debug:/app-src/tmp
```

## Source Files

| #    | Export                                               |
|------|------------------------------------------------------|
| NAV1 | Alle Kontakte aus Navision                           |
| NAV2 | Stammmitgliedschaften                                |
| NAV3 | Zusatzmitgliedschaften                               |
| NAV4 | Sektionsfunktionäre                                  |
| NAV5 | Hüttenbeziehungen (Hütten und Hüttenfunktionäre)     |
| NAV6 | Sektionen und Ortsgruppen                            |
| NAV7 | Abonenten Die Alpen                                  |
| WSO21 | Basic Accounts und Password Hashes                  |
| WSO22 | SAC Tourenportal Abonnenten                         |

details siehe SAC Confluence/Jira

## Hitobito SAC Import 1: import:people

Diesen Import immer als erstes laufen lassen damit alle Personen in der DB vorhanden sind und entsprechend in andere Gruppen via Rollen assigned werden können.

Importiert alle Navision Kontakte und legt diese Unter `Top-Layer > Navision Import` ab.

`rake import:people FILE=tmp/xlsx/personen.xlsx REIMPORT_ALL=true`

Import Source File: **NAV1**

## Hitobito SAC Import 2: import:sektionen

Mit diesem Import werden alle Sektionen und Ortsgruppen importiert. 
Auf jeder Sektion/Ortsgruppe werden auch Attribute wie z.B. Kanton, Gründungsjahr usw. gesetzt

`rake import:sektionen`

file: $CORE_ROOT/tmp/xlsx/sektionen.xlsx

- Importiert Sektionen/Ortsgruppen und erstellt deren Unterordnerstruktur

Import Source File: **NAV6**

## Hitobito SAC Import 3: import:huts

`rake import:huts`

file: $CORE_ROOT/tmp/xlsx/huetten_beziehungen.xlsx

Import Source File: **NAV5**

## Hitobito SAC Import 4: import:memberships

`rails import:memberships FILE=tmp/xlsx/mitglieder_aktive.xlsx REIMPORT_ALL=true)`

Import Source File: **NAV2**

## Hitobito SAC Import 5: import:additional_memberships

Sicherstellen das Import Mitglieder Stammsektion bereits ausgeführt wurde. Eine Mitgliedschaft Zusatzsektion ist nur möglich falls bereits eine Mitglied Stammsektion Rolle vorhanden ist.

`rails import:additional_memberships FILE=tmp/xlsx/zusatzmitgliedschaften.xlsx REIMPORT_ALL=true)`

Import Source File: **NAV3**

## Delete all Sektions

```ruby
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```
