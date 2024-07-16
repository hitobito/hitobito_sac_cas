# SAC/CAS specific imports

```txt
oc rsync tmp/xlsx delayed-job-db8bb7688-c6nrn-debug:/app-src/tmp
```

## 1. import:people

Diesen Import immer als erstes laufen lassen damit alle Personen in der DB vorhanden sind und entsprechend in andere Gruppen via Rollen assigned werden können.

Importiert alle Navision Kontakte und legt diese Unter `Top-Layer > Navision Import` ab.

`rake import:people FILE=tmp/xlsx/personen.xlsx REIMPORT_ALL=true`

## 2. import:sektionen

Mit diesem Import werden alle Sektionen und Ortsgruppen importiert. 
Auf jeder Sektion/Ortsgruppe werden auch Attribute wie z.B. Kanton, Gründungsjahr usw. gesetzt

`rake import:sektionen`

file: $CORE_ROOT/tmp/xlsx/sektionen.xlsx

- Importiert Sektionen/Ortsgruppen und erstellt deren Unterordnerstruktur

## 3. import:huts

`rake import:huts`

file: $CORE_ROOT/tmp/xlsx/huetten_beziehungen.xlsx

## 4. import:memberships

`rails import:memberships FILE=tmp/xlsx/mitglieder_aktive.xlsx REIMPORT_ALL=true)`

## 5. import:additional_memberships

Sicherstellen das Import Mitglieder Stammsektion bereits ausgeführt wurde. Eine Mitgliedschaft Zusatzsektion ist nur möglich falls bereits eine Mitglied Stammsektion Rolle vorhanden ist.

`rails import:additional_memberships FILE=tmp/xlsx/zusatzmitgliedschaften.xlsx REIMPORT_ALL=true)`

## Delete all Sektions

```ruby
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```
