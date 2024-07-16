# SAC/CAS specific imports

```txt
oc rsync tmp/xlsx delayed-job-db8bb7688-c6nrn-debug:/app-src/tmp
```

## 1. - People Import

Diesen Import immer als erstes laufen lassen damit alle Personen in der DB vorhanden sind und entsprechend in andere Gruppen via Rollen assigend werden können.

Importiert alle Navision Kontakte und legt diese Unter 'Top-Layer > Navision Import' ab.

`rails import:people FILE=tmp/xlsx/personen.xlsx REIMPORT_ALL=true`

## 2. - Import sektionen

Diesen Import laufen lassen damit alle Sektionen vorhanden sind.

`rails import:sektionen`

file: $CORE_ROOT/tmp/xlsx/sektionen.xlsx

## 3. Import huts

`rails import:huts`

file: $CORE_ROOT/tmp/xlsx/huetten_beziehungen.xlsx

## 4. Import Mitglieder Stammsektion

`rails import:memberships FILE=tmp/xlsx/mitglieder_aktive.xlsx REIMPORT_ALL=true)`

## 5. Import Mitglieder Zusatzsektion

Sicherstellen das Import Mitglieder Stammsektion bereits ausgeführt wurde. Eine Mitgliedschaft Zusatzsektion ist nur möglich falls bereits eine Mitglied Stammsektion Rolle vorhanden ist.

`rails import:additional_memberships FILE=tmp/xlsx/zusatzmitgliedschaften.xlsx REIMPORT_ALL=true)`

## Delete all Sektions

```ruby
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```
