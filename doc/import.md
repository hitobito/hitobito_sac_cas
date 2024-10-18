# Datenimport

Hitobito löst verschiedene Systeme vom SAC/CAS ab. Um Datenfehler zu finden und vom SAC/CAS bereinigen zu lassen, soll
beim Import ein Report erstellt werden, der auf Validierungsfehler hinweist. Durch Abhängigkeiten und verschiedenen
Datenquellen, erfolgt der Import in mehreren Schritten. Schlussendlich sollen die Daten mittels des Imports ins
Hitobito migriert werden. Danach wird der hier beschriebene Datenimport nicht mehr benötigt.

* [Konzepte](#Konzepte)
* [Quelldaten](#Quelldaten)
* [CSV Report](#CSV-Report)
* [Importe](#Importe)
* [Ausführen der Imports auf Openshift](#Ausführen-der-Imports-auf-Openshift)
* [Development](#Development)

## Konzepte

- Jeder Import kann mehrfach ausgeführt werden
- Bei einem weiteren Ausführen werden die einzelnen Daten resettet: z.B. werden alle Mitgliederrollen einer Person erst gelöscht bevor diese Importiert werden
- Ein Import erstellt beim Ausführen grundsätzlich einen [CSV Report](#CSV-Report)
- `SacImports` ist der Namespace für sämtlichen Import-Code
- Imports werden via rake Tasks getriggert (`lib/tasks/sac_imports.rake`)

## Quelldaten

Die Daten bestehen aus verschiedenen .csv-Dateien. Die .csv-Dateien haben folgende Eigenschaften:

- **Encoding**: UTF-8
- **Delimiter**: ,
- **Zellen**: Zeichenketten umfasst mit "
- **Header**: erste Zeile

Die Dateien sind im Nextcloud abgelegt (Ordner sac-trans) **Die Daten dürfen nur anonymisiert im öffentlichen Bereich verwendet werden!**

| #     | Inhalt                                               | Art       |
|-------|------------------------------------------------------|-----------|
| NAV1  | Alle Kontakte (natürliche und juristische Personen)  | via CSV   |
| NAV2  | Rollen und Gruppen                                   | via CSV   |
| NAV3  | Qualifikationen                                      | via CSV   |
| NAV5  | Hüttenbeziehungen (Hütten und Hüttenfunktionäre)     | via XLSX  |
| NAV6  | Sektionen und Ortsgruppen                            | via CSV   |
| NAV7  | Qualifikationsarten                                  | via Seeds |
| NAV8  | Austrittsgründe                                      | via CSV   |
| WSO21 | Datenexport aus WSO21                                | via CSV   |

Weitere informationen sind in [HIT-490](https://saccas.atlassian.net/browse/HIT-490) zu finden.

Siehe [SacImports::CsvSource](../app/domain/sac_imports/csv_source.rb)

## CSV Report

Jeder Import erstellt einen CSV Report in RAILS_CORE_ROOT/log/sac_imports/. In diesem wird pro Import-Zeile eine Zeile im Report CSV erstellt.

`$IMPORT_NAME_$TIMESTAMP.csv`, e.g. `nav1-1_people_2024-06-01-12:00.csv`

Siehe [SacImports::CsvReport](../app/domain/sac_imports/csv_report.rb)

## Importe

Beim Seeden werden folgende Daten importiert:

- Qualifikationsarten: `hitobito_sac_cas/db/seeds/qualification_kinds.rb`

Die Importe müssen in folgender Reihenfolge ausgeführt werden:

```txt
sac_imports:nav1-1_people
sac_imports:wso21-1_people
sac_imports:nav6-1_sac_sections
sac_imports:nav2-1_membership_roles
sac_imports:nav1-2_sac_families
sac_imports:nav3-1_qualifications
sac_imports:nav5-1_huts
sac_imports:nav8-1_austrittsgruende
sac_imports:nav1-2_membership_years_report
```

Importe können mit `bundle exec rails sac_imports:nav6-1_sac_section` ausgeführt werden.

### `sac_imports:nav6-1_sac_section`

#### Alle Sektionen vorher löschen

Optinonal falls man dies resetten möchte

```ruby
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```

### `sac_imports:nav1-1_people`

optional kann eine navision id angegeben ab der Row ab dem der Import gestartet werden soll.
`START_AT_NAVISION_ID=42 rails sac_imports:nav1-1_people`

#### Diskrepanzen:

- `Street Name` und `Street No_`, sowie `Address` passen nicht immer zusammen, wobei `Street Name` und `Street No_` oft nicht ausgefüllt sind.

#### Hinweise:

- Geschlecht `2` bedeutet es handelt sich um eine Firma.
- Wenn eine Person eine E-Mail hat welche bereits als Haupt-Emaildadresse existier wird sie mit einer Emailadresse unter
  `additional_emails` angelegt. (Siehe <https://github.com/hitobito/hitobito_sac_cas/issues/1079>)


### `sac_imports:nav1-2_membership_years_report`

You can run the import with: `bundle exec rails sac_imports:1_people`

### `sac_imports:wso21-1_people`

### `sac_imports:nav2-1_membership_roles`

Importiert alle aktiven und inaktiven Mitglieds-Rollen (Stammsektion, Zusatzsektion)

### `sac_imports:nav1-2_sac_families`

Setzt die `household_key` bei den Personen welche die `Group::SektionsMitglieder::Mitglied` Rolle mit beitragskategorie
:family haben.

### `sac_imports:nav3-1_qualifications`

### `sac_imports:nav5-1_huts`

Importiert alle Hütten und hängt diese unter den Sektionen entsprechend ein. Ausserdem werden die Hüttenfunktionärs-Rollen gleich mitangelegt.

`rake sac_imports:nav5-1_huts`

Datei: $CORE_ROOT/tmp/xlsx/huetten_beziehungen.xlsx

### `sac_imports:nav8-1_austrittsgruende`

## Ausführen der Imports auf Openshift

1. Im $RAILS_CORE_ROOT/tmp/sac_import_src/ die entsprechenden CSV-Dateien ablegen (Siehe [CSV Source Files](#csv-source-files))
2. In Openshift einloggen und in das gewünschte Projekt wechseln
3. Sicherstellen das das PVC mit dem Namen `sac-imports` vorhanden ist (auf sac-int/sac-prod aktuell vorhanden)
4. hitobito_sac_cas/bin/ose-sac-import-shell ausführen
5. Beten das alles gut geht
6. In der Shell im rails-sac-imports Pod die gewünschten Imports ausführen
7. exit um die Shell zu verlassen
8. CSV Log files auf deinem Rechner in hitobito_sac_cas/tmp/sac_import-logs einsehen und ggf. an SAC weiterleiten
9. Falls der pod nicht mehr benötigt wird, diesen killen `oc delete pod rails-sac-imports`

Nach dem Ausführen der Importe müssen nacheinander noch die folgenden Jobs ausgeführt werden:

1. Datenqualität Prüfung für alle Personen: `People::DataQualityCheckerJob.new.perform`
2. Abacus sync aller Mitglieder: `Invoices::Abacus::TransmitAllMembersJob.new.perform`

## Development

- Zufällige Zeilen aus einer .csv-Datei in eine neue .csv-Datei schreiben:
  ```bash
  head -n 1 input.csv > output.csv && tail -n +2 input.csv | shuf -n 2000 >> output.csv
  ```
- `RAILS_SILENCE_ACTIVE_RECORD=1` kann die Geschwindigkeit des Imports erhöhen.
- In `/spec/fixtures/files/sac_imports_src/sac_imports_fixture.ods` werden die Fixtures verfasst und mit dem Skript `hitobito_sac_cas/spec/fixtures/files/sac_imports_src/export_sac_imports_fixture.sh` die jeweiligen Fixtures im CSV-Format erstellt. Es wird LibreOffice 7.2 oder neuer benötigt.
- `sac_imports.rake` sucht in `hitobito/tmp/sac_imports_src` nach den CSV-Dateien die importiert werden sollen. Der Name der CSV-Datei muss mit der ID (Muster: `[ID]_*.csv`) beginnen: bspw. NAV1_people.csv
