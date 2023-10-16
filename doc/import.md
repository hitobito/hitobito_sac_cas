# SAC/CAS specific imports

```
oc rsync tmp/xlsx delayed-job-db8bb7688-c6nrn-debug:/app-src/tmp
```

## Import sections

`rails import:huts`

## Import huts

`rails import:huts`

## Import people

`rails import:bluemlisalp_people`

## Delete all Sektions

```
Group::Ortsgruppe.all.each { |o| o.children.each(&:really_destroy! }
Group::Sektion.all.find_each { |s| s.children.each(&:really_destroy!) }
Group::Sektion.all.find_each { |s| s.really_destroy! }
```
