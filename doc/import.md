# Datenimport

Hitobito lösst verschiedene Systeme vom SAC/CAS ab. Um Datenfehler zu finden und vom SAC/CAS bereinigen zu lassen, soll
beim Import ein Report erstellt werden, der auf Validierungsfehler hinweist. Durch Abhängigkeiten und verschiedenen
Datenquellen, erfolgt der Import in mehreren Schritten. Schlussendlich sollen die Daten mittels des Imports ins
Hitobito migriert werden. Danach wird der hier beschriebene Datenimport nicht mehr benötigt.

## Quelldaten

Die Daten bestehen aus verschiedenen .csv-Dateien. Die .csv-Dateien haben folgende Eigenschaften:

- Encoding: UTF-8
- Delimiter: ,
- Header: erste Zeile

Die Dateien sind im Nextcloud abgelegt. **Die Daten dürfen nur anonymisiert im öffentlichen Bereich verwendet werden!**

| #    | Inhalt                                               |
|------|------------------------------------------------------|
| NAV1 | Alle Kontakte (natürliche und juristische Personen)  |
| NAV2 | Stammmitgliedschaften                                |
| NAV4 | Sektionsfunktionäre                                  |
| NAV5 | Hüttenbeziehungen (Hütten und Hüttenfunktionäre)     |
| NAV6 | Sektionen und Ortsgruppen                            |
| NAV7 | Abonenten Die Alpen                                  |
| WSO2 | Datenexport aus WSO2                                |

Weitere informationen sind in [HIT-490](https://saccas.atlassian.net/browse/HIT-490) zu finden.

Siehe [SacImports::CsvSource](../app/domain/sac_imports/csv_source_file.rb)

## Entwickler

- Zufällige Zeilen aus einer .csv-Datei in eine neue .csv-Datei schreiben:
  ```bash
  head -n 1 input.csv > output.csv && tail -n +2 input.csv | shuf -n 2000 >> output.csv
  ```
- `RAILS_SILENCE_ACTIVE_RECORD=1` kann die Geschwindigkeit des Imports erhöhen.

## CSV Report

Jeder Import erstellt einen CSV Report in RAILS_CORE_ROOT/log/sac_imports/. In diesem wird pro Import-Zeile eine Zeile im Report CSV erstellt.

`$IMPORT_NAME_$TIMESTAMP.csv`, e.g. `1_people_2024-06-01-12:00.csv`

Siehe [SacImports::CsvReport](../app/domain/sac_imports/csv_report.rb)

## Importe

### `NAV1`: sac_imports:1_people

Dieser Import soll immer zuerst ausgeführt werden, damit den Personen in den weiteren Schritten die Rollen zugeordnet werden können.

You can run the import with: `RAILS_SILENCE_ACTIVE_RECORD=1 bundle exec rails sac_imports:1_people`

#### Diskrepanzen:

- `Street Name` und `Street No_`, sowie `Address` passen nicht immer zusammen, wobei `Street Name` und `Street No_` oft nicht ausgefüllt sind.

#### Hinweise:

- Geschlecht `2` bedeutet es handelt sich um eine Firma.


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

- Import Source File: **NAV1**
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
