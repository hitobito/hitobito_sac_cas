# SAC/CAS specific imports

```
oc rsync ../hitobito_sac_cas/db/seeds/production/ delayed-job-764855cbfd-6mqfl-debug:/opt/app-root/src/vendor/wagons/hitobito_sac_cas/db/seeds/production/
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
