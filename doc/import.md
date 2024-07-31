# SAC/CAS specific imports

```txt
oc rsync tmp/xlsx delayed-job-db8bb7688-c6nrn-debug:/app-src/tmp
```

## CSV Source Files

| #    | Export                                               |
|------|------------------------------------------------------|
| NAV1 | Alle Kontakte aus Navision                           |
| NAV2 | Stammmitgliedschaften                                |
| NAV3 | Zusatzmitgliedschaften                               |
| NAV4 | Sektionsfunktionäre                                  |
| NAV5 | Hüttenbeziehungen (Hütten und Hüttenfunktionäre)     |
| NAV6 | Sektionen und Ortsgruppen                            |
| NAV7 | Abonenten Die Alpen                                  |
| WSO21 | Datenexport aus WSO2                                |

details siehe SAC Jira HIT-490

Siehe [SacImports::CsvSourceFile](../app/domain/sac_imports/csv_source_file.rb)

## CSV Report

Jeder Import erstellt einen CSV Report in RAILS_CORE_ROOT/log/sac_imports/. In diesem wird pro Import-Zeile eine Zeile im Report CSV erstellt.

`$IMPORT_NAME_$TIMESTAMP.csv`, e.g. `1_people_2024-06-01-12:00.csv`

Siehe [SacImports::CsvReport](../app/domain/sac_imports/csv_report.rb)

## 1: sac_imports:1_people

Diesen Import immer als erstes laufen lassen damit alle Personen in der DB vorhanden sind und entsprechend in andere Gruppen via Rollen assigned werden können.

Importiert alle Navision Kontakte und legt diese Unter `Top-Layer > Navision Import` ab.

`rake sac_imports:1_people FILE=tmp/xlsx/personen.xlsx REIMPORT_ALL=true`

Import Source File: **NAV1**

## 2: sac_imports:2_sektionen

Mit diesem Import werden alle Sektionen und Ortsgruppen importiert. 
Auf jeder Sektion/Ortsgruppe werden auch Attribute wie z.B. Kanton, Gründungsjahr usw. gesetzt

`rake sac_imports:2_sektionen`

file: $CORE_ROOT/tmp/xlsx/sektionen.xlsx

- Importiert Sektionen/Ortsgruppen und erstellt deren Unterordnerstruktur

Import Source File: **NAV6**

## 3: sac_imports:3_huts

Importiert alle Hütten und hängt diese unter den Sektionen entsprechend ein. Ausserdem werden die Hüttenfunktionärs-Rollen gleich mitangelegt.

`rake sac_imports:huts`

file: $CORE_ROOT/tmp/xlsx/huetten_beziehungen.xlsx

Import Source File: **NAV5**

## 4: sac_imports:4_memberships

Importiert alle aktiven und inaktiven Stammsektions-Mitglied-Rollen. 

`rake sac_imports:memberships FILE=tmp/xlsx/mitglieder_aktive.xlsx REIMPORT_ALL=true)`

Import Source File: **NAV2**

## 5: sac_imports:5_additional_memberships

Sicherstellen das Import Mitglieder Stammsektion bereits ausgeführt wurde. Eine Mitgliedschaft Zusatzsektion ist nur möglich falls bereits eine Mitglied Stammsektion Rolle vorhanden ist.

`rake sac_imports:5_additional_memberships FILE=tmp/xlsx/zusatzmitgliedschaften.xlsx REIMPORT_ALL=true)`

Import Source File: **NAV3**

## 6: sac_imports:6_membership_years_report

`rake sac_imports:6_membership_years_report`

- Import Source File: **NAV2**
- CSV Report Output: `RAILS_CORE_ROOT/log/sac_imports/6_membership_years_report_2024-06-01-12:00.csv`

## 7: sac_imports:7_wso2_password_hashes

`rake sac_imports:7_wso2_password_hashes`

- Import Source File: **WSO21**
- CSV Report Output: `RAILS_CORE_ROOT/log/sac_imports/7_wso2_password_hashes_2024-06-01-12:00.csv`

## Delete all Sektions

```ruby
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```
