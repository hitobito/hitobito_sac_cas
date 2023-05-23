# Hitobito SAC CAS

This hitobito wagon defines the organization hierarchy with groups and roles
of SAC CAS.


## Organization Hierarchy

```
* Schweizer Alpen-Club SAC
  * Geschäftsstelle
    * Verwaltung: [:layer_and_below_full, :finance, :impersonation]
    * Verwaltung (nur lesend): [:layer_and_below_read]
    * IT Support: [:layer_and_below_full, :finance, :admin, :impersonation]
  * Externe Kontakte
    * Kontakt: []
  * Sektion
    * Funktionäre
      * Präsidium: []
      * Vizepräsidium: []
      * Funktionär*in: []
      * Verwaltung: [:layer_and_below_full]
      * Verwaltung (nur lesend): [:layer_and_below_read]
    * Mitglieder
      * Einzel: []
      * Jugendmitglied: []
      * Frei Kind: []
      * Frei Fam: []
      * Abonnement: []
      * Geschenkmitgliedschaft: []
      * Ehrenmitglied: []
      * Begünstigt: []
    * Tourenkommission
      * Tourenchef*in Sommer: [:group_full]
      * Tourenchef*in Winter: [:group_full]
      * Tourenchef*in Klettern: [:group_full]
      * Tourenchef*in Senioren: [:group_full]
      * Tourenleiter*in Sommer: [:group_full]
      * Tourenleiter*in Winter: [:group_full]
    * Hütte
      * Hütte
        * Hüttenwart*in: [:group_full]
        * Hüttenwartspartner*in: [:group_full]
        * Hüttenchef*in: [:group_full]
        * Mitarbeiter*in: []
        * Funktionär*in: []
```

(Output of rake app:hitobito:roles)
