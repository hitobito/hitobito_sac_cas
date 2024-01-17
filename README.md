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
* Ortsgruppe
* Global
  * Funktionäre
    * Präsidium: []
    * Mitgliederverwaltung: [:layer_and_below_full]
    * Administration: [:layer_and_below_full]
    * Administration (nur lesend): [:layer_and_below_read]
    * Umweltbeauftragte*r: []
    * Kulturbeauftragte*r: []
    * Andere: []
  * Mitglieder
    * Mitglied (Stammsektion): []
    * Mitglied (Zusatzsektion): []
    * Ehrenmitglied: []
    * Begünstigt: []
  * Neuanmeldungen (zur Freigabe)
    * Neuanmeldung (Stammsektion): []
    * Neuanmeldung (Zusatzsektion): []
  * Neuanmeldungen
    * Neuanmeldung (Stammsektion): []
    * Neuanmeldung (Zusatzsektion): []
  * Tourenkommission
    * Tourenchef*in Sommer: [:group_full]
    * Tourenchef*in Winter: [:group_full]
    * Tourenchef*in Klettern: [:group_full]
    * Tourenchef*in Senioren: [:group_full]
    * Tourenleiter*in: []
  * Hüttenkommission
    * Hüttenobmann*frau: [:group_and_below_read]
    * Andere: [:group_read]
```

(Output of rake app:hitobito:roles)
