# Hitobito SAC CAS

This hitobito wagon defines the organization hierarchy with groups and roles
of SAC CAS.


## Organization Hierarchy

```
* Schweizer Alpen-Club SAC
  * Geschäftsstelle
    * Mitgliederdienst: [:layer_and_below_full, :impersonation]
    * Kursorganisation: [:layer_full, :layer_and_below_read, :impersonation]
    * Fundraising: [:layer_and_below_read]
    * Kommunikation: [:layer_full, :layer_and_below_read]
    * Rechnungswesen: [:layer_full, :layer_and_below_read]
    * Leistungssport: [:layer_and_below_read]
    * Hütten & Umwelt: [:layer_and_below_full]
    * Digitalisierung & IT: [:layer_and_below_full, :admin, :impersonation]
  * Externe Kontakte
    * Kontakt: []
* Sektion
* Hütte
  * Hütte
    * Hüttenwart*in: [:group_full]
    * Hüttenwartspartner*in: [:group_full]
    * Hüttenchef*in: [:group_full]
    * Mitarbeiter*in: []
    * Schlüsseldepot: []
    * Funktionär*in: []
* Ortsgruppe
* Global
  * Funktionäre
    * Präsidium: []
    * Vizepräsidium: []
    * Mitgliederdienst: [:layer_and_below_full]
    * Funktionär*in: []
    * Verwaltung: [:layer_and_below_full]
    * Verwaltung (nur lesend): [:layer_and_below_read]
    * Hüttenobmann: [:layer_read]
  * Mitglieder
    * Mitglied: []
    * Abonnement: []
    * Ehrenmitglied: []
    * Begünstigt: []
  * Neuanmeldungen (zur Freigabe)
    * Neuanmeldung: []
  * Neuanmeldungen
    * Neuanmeldung: []
  * Tourenkommission
    * Tourenchef*in Sommer: [:group_full]
    * Tourenchef*in Winter: [:group_full]
    * Tourenchef*in Klettern: [:group_full]
    * Tourenchef*in Senioren: [:group_full]
    * Tourenleiter*in Sommer: [:group_read]
    * Tourenleiter*in Winter: [:group_read]
```

(Output of rake app:hitobito:roles)
