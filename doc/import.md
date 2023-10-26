# SAC/CAS specific imports

```
oc rsync tmp/xlsx delayed-job-db8bb7688-c6nrn-debug:/app-src/tmp
```

## Import sektionen

`rails import:sektionen`

## Import huts

`rails import:huts`

## Import Mitglieder to Sektion

`rails import:sektions_mitglieder FILE=sektions_mitglieder.xlsx`


## Delete all Sektions

```
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy! }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```
