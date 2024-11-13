# Datenimport

## PROD Import

Import Files finden sich auf [Nextcloud](https://files.puzzle.ch/apps/files/files/7246438?dir=/sac-trans), die neuesten Dateien sind im `latest` die
Reports legen wir in den Folder `csv-logs`. Am besten soll dieser Folder ins erwartete Verzeichnis `tmp/sac_imports_src` gelinkt werden

```
  ln -s ~/Documents/Nextcloud/sac-trans/latest/ sac_imports_src
```

Wir setzen env Variablen analog zur prod

```
  export RAILS_DB_SCHEMA=database
  export RAILS_DB_NAME=hit_sac_cas_prod
  export DISABLE_SPRING=1
```

Der Import erfolgt mittels rake tasks in der folgenden Reihenfolge

0. `rails db:drop db:create db:migrate wagon:migrate` # nicht gleichzeitig mit `seed` ausführen!
1. `NO_ENV=true rails db:seed wagon:seed` # !!! **NO_ENV** muss gesetzt sein, sonst werden dev seeds geseedet !!!
2. `rails sac_imports:nav6-1_sac_section` # Import Sektionen und Ortsgruppen
3. `rails sac_imports:nav5-1_huts` # Importiert Hütten Gruppen und Hüttenkontakte
4. `rails sac_imports:nav2b-1_missing_groups` # Importiert fehlende Gruppen
5. `rails sac_imports:nav1-1_people` # Importiert Personen aus navision
6. `rails sac_imports:wso21-1_people` # Importiert alte Passwörter und Personen die nicht im Navision sind
7. `rails sac_imports:nav3-1_qualifications` # Importiert Qualifikationen der Personen
8. `rails sac_imports:nav2a-1_membership_roles` # Importiert alle Mitgliedschaftsrollen (Stammsektion,Zusatzsektion)
9. `rails sac_imports:nav2a-2_set_family_main_person` # Setzt family main person Flag
10. `rails sac_imports:nav2a-3_families` # Macht Familien auf basis bisher importierter daten (kein file)
11. `rails sac_imports:nav2b-2_non_membership_roles` # Importiert alle anderen Rollen
12. `rails sac_imports:nav8-1_austrittsgruende` # Fällt eventuell weg
13. `rails sac_imports:nav1-2_membership_years_report` # Generiert Mitgliedsschaftsjahre Report

Es wird immmer eine vollständig DB lokal befüllt welche dann als ganzes auf PROD eingespielt werden kann.

Importieren auf dem lokalen system

```
  rails db:drop db:create
  cat ~/tmp/fix-family-main-people.dump |  rails dbconsole -p
```

Exportieren der custom contents von INT und tokens von PROD

```
  oc project hit-sac-cas-int
  ./bin/with_cluster_db rails sac_exports:custom_contents

  oc project hit-sac-cas-prod
  ./bin/with_cluster_db rails sac_exports:tokens_and_apps
```

Einspielen dieser seeds in lokale DB

```
  rails r 'CustomContent.destroy_all'
  rails r 'CustomContent::Translation.destroy_all'
  rails r ../hitobito_sac_cas/db/seeds/custom_contents.rb
  rails r ../hitobito_sac_cas/db/seeds/tokens_and_apps.rb
```

Dump exportieren und auf prod einspielen

```
  PGPASSWORD=hitobito pg_dump -cOx -h localhost -U hitobito hit_sac_cas_prod | gzip > tmp/hit_sac_cas_prod.sql.gz
  unset PGUSER
  unset PGPASSWORD

  oc project hit-sac-cas-prod
  zcat tmp/hit_sac_cas_prod.sql.gz | ./bin/with_cluster_db rails dbconsole -p
```

Wie umgehen mit schema name?? (beste variante wäre beim lokale arbeiten schon das database schema zu verwenden)

### Was noch zu definieren ist

- Wann und wo sind folgenden Daten final und können in den Import integriert werden?

  - CustomContents (global) -> per 30. Nov in Excel Datei geliefert, als seeds hinterlegen
  - OIDC Applikationen (global) -> per 30. Nov in PROD eingepflegt
  - ServiceTokens (pro Gruppe) -> per 30. Nov in PROD eingepflegt

  Ab 1. Dez unveränderte API keys etc. in PROD

- Noch zu definierende Punkte

  - Konfiguration von der root gruppe (mailing liste)
  - SAC Newsletter (und ev. weiter) Mailingliste (Abo Gruppen) (SAC-Newsletter
    SAC-Inside Newsletter
    Tourenleiter Newsletter
    Die Alpen (physisch)
    Die Alpen (digital)
    Spendenaufrufe)
  - Newsletter opt-in / opt-out pro Person
  - Mailchimp Newsletter export (Andi Gurtner)
  - KVS import
  - Wann werden die mails wieder scharfgeschalten

### Ablauf

- Daten lokal importieren
- Pods herunterfahren
- DB Dump auf prod cluster einspielen
- Pods hochfahren
- TBD -> Emails scharf schalten??

## Bisherige Import info

Hitobito löst verschiedene Systeme vom SAC/CAS ab. Um Datenfehler zu finden und vom SAC/CAS bereinigen zu lassen, soll
beim Import ein Report erstellt werden, der auf Validierungsfehler hinweist. Durch Abhängigkeiten und verschiedenen
Datenquellen, erfolgt der Import in mehreren Schritten. Schlussendlich sollen die Daten mittels des Imports ins
Hitobito migriert werden. Danach wird der hier beschriebene Datenimport nicht mehr benötigt.

- [Konzepte](#Konzepte)
- [Quelldaten](#Quelldaten)
- [CSV Report](#CSV-Report)
- [Importe](#Importe)
- [Ausführen der Imports auf Openshift](#Ausführen-der-Imports-auf-Openshift)
- [Development](#Development)

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

| #     | Inhalt                                              | Art       |
| ----- | --------------------------------------------------- | --------- |
| NAV1  | Alle Kontakte (natürliche und juristische Personen) | via CSV   |
| NAV2  | Rollen und Gruppen                                  | via CSV   |
| NAV3  | Qualifikationen                                     | via CSV   |
| NAV5  | Hüttenbeziehungen (Hütten und Hüttenfunktionäre)    | via XLSX  |
| NAV6  | Sektionen und Ortsgruppen                           | via CSV   |
| NAV7  | Qualifikationsarten                                 | via Seeds |
| NAV8  | Austrittsgründe                                     | via CSV   |
| WSO21 | Datenexport aus WSO21                               | via CSV   |

Weitere informationen sind in [HIT-490](https://saccas.atlassian.net/browse/HIT-490) zu finden.

Siehe [SacImports::CsvSource](../app/domain/sac_imports/csv_source.rb)

## CSV Report

Jeder Import erstellt einen CSV Report in RAILS_CORE_ROOT/log/sac_imports/. In diesem wird pro Import-Zeile eine Zeile im Report CSV erstellt.

`$IMPORT_NAME_$TIMESTAMP.csv`, e.g. `nav1-1_people_2024-06-01-12:00.csv`

Siehe [SacImports::CsvReport](../app/domain/sac_imports/csv_report.rb)

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

`FILE=./tmp/sac_imports_src/Huetten_Beziehungen_20230704.xlsx rails sac_imports:nav5-1_huts`

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
