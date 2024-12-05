# Datenimport

## Was noch zu definieren ist

- Wann sollen worker laufen (abacus, anderes) -> wunsch direkt nach import?
- Wann sollen emails scharfgeschalten werden?

## Ablauf - Entwurf Puzzle (mit SAC abklären)

- Daten lokal importieren und DataQualityCheckerJob laufen lassen

- Pods herunterfahren
- Abacus Secret anpassen
- DB Dump auf prod cluster einspielen
- Pods hochfahren mit workern
- Abacus Sync job starten

## Lokaler Datenimport

Import Files finden sich auf [Nextcloud](https://files.puzzle.ch/apps/files/files/7246438?dir=/sac-trans), die neuesten Dateien sind im `latest` die
Reports legen wir in den Folder `csv-logs`. Am besten soll dieser Folder ins erwartete Verzeichnis `tmp/sac_imports_src` gelinkt werden

Es wird immmer eine vollständig DB lokal befüllt welche dann als ganzes auf PROD eingespielt werden kann.

```
  ln -s ~/Documents/Nextcloud/sac-trans/latest/ sac_imports_src
```

Wir setzen env Variablen analog zur prod (unklar noch wie mit dem DB_SCHEMA)

```
  export RAILS_DB_NAME=hit_sac_cas_prod
  export ROOT_PW="pw-aus-cryptopus"
```

Zuerst werden seed daten von int und prod gelesen (Puzzle Netz oder VPN aktiv)

1. `rails sac_exports:write_seeds` # Liest Daten von int und prod und schreibt diese als seed daten nach hitobito_sac_cas/db/seeds

Anschliessend erfolgt der Import mittels rake tasks in der folgenden Reihenfolge

1. `rails db:drop db:create db:migrate wagon:migrate` # nicht gleichzeitig mit `seed` ausführen!
2. `NO_ENV=true rails db:seed wagon:seed` # !!! **NO_ENV** muss gesetzt sein, sonst werden dev seeds geseedet !!!
3. `rails sac_imports:all`

Das führt die folgenden rake tasks in der richtigen Reihenfolge aus

4. `rails sac_imports:nav6-1_sac_section` # Import Sektionen und Ortsgruppen
5. `rails sac_imports:nav5-1_huts` # Importiert Hütten Gruppen und Hüttenkontakte
6. `rails sac_imports:nav2b-1_missing_groups` # Importiert fehlende Gruppen
7. `rails sac_imports:nav1-1_people` # Importiert Personen aus navision
8. `rails sac_imports:nav3-1_qualifications` # Importiert Qualifikationen der Personen
9. `rails sac_imports:nav2a-1_membership_roles` # Importiert alle Mitgliedschaftsrollen (Stammsektion,Zusatzsektion)
10. `rails sac_imports:nav2a-2_set_family_main_person` # Setzt family main person Flag
11. `rails sac_imports:nav2a-3_families` # Macht Familien auf basis bisher importierter daten (kein file)
12. `rails sac_imports:wso21-1_people` # Importiert alte Passwörter und Personen die nicht im Navision sind
13. `rails sac_imports:nav2b-2_non_membership_roles` # Importiert alle anderen Rollen
14. `rails sac_imports:nav8-1_austrittsgruende` # Fällt eventuell weg
15. `rails sac_imports:nav1-2_membership_years_report` # Generiert Mitgliedsschaftsjahre Report
16. `rails sac_imports::update_sac_family_address` # Aktualisiert Familien addressen
17. `rails sac_imports:cleanup` # Verschiedene Cleanup Tasks

Importieren auf dem lokalen system

```
  rails db:drop db:create
  cat ~/tmp/fix-family-main-people.dump |  rails dbconsole -p
```

Einspielen dieser seeds in lokale DB und user vorbereiten
CustomContents laden schlägt beim ersten mal fehl -> löschen und neu seeden

```
  rails r 'CustomContent.destroy_all; CustomContent::Translation.destroy_all'
  rails r 'Delayed::Job.destroy_all;' # sollte keine löschen müssen
  rails r ../hitobito_sac_cas/db/seeds/custom_contents.rb
  rails r ../hitobito_sac_cas/db/seeds/tokens_and_apps.rb
  rails r "Person.root.update(password: ENV.fetch('ROOT_PW'), password_confirmation: ENV.fetch('ROOT_PW'))"
```

Schema umbenennen

```
  echo 'ALTER SCHEMA public RENAME TO database' | rails dbconsole -p
```

Dump exportieren

```
  PGPASSWORD=hitobito pg_dump -cOx -h localhost -U hitobito hit_sac_cas_prod | gzip > tmp/hit_sac_cas_prod.sql.gz
  unset PGUSER
  unset PGPASSWORD
```

## Pods herunterfahren

Via argo rails und delayed jobs auf 0 skalieren

## Lokalen Dump auf prod Einspielen

```
  oc project hit-sac-cas-prod
  zcat tmp/hit_sac_cas_prod.sql.gz | ./bin/with_cluster_db rails dbconsole -p
```

## Pods hochskalieren und Abacus Sync starten

Auf dem prod system anmeldungen systen

```
  Invoices::Abacus::TransmitAllMembersJob.new.enqueue!
```
