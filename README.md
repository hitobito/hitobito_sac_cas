# Hitobito SAC CAS

This hitobito wagon defines the organization hierarchy with groups and roles
of SAC CAS.


## Organization Hierarchy

```
* Zentralverband
  * Ressort
    * Leitung: [:group_full]
    * Mitarbeitende: []
    * Rechnungswesen: [:layer_and_below_full, :finance]
    * Mitgliederverwaltung: [:layer_and_below_full]
    * IT Support: [:layer_and_below_full, :admin]
  * Externe Kontakte
    * Externer Kontakt: []
* Sektion
  * Sektion
    * Kontaktperson: [:contact_data]
  * Vorstand
    * Präsident: [:layer_and_below_read, :contact_data]
    * Vizepräsident: [:layer_and_below_read, :contact_data]
    * Vorstandsmitglied: [:layer_read, :contact_data]
    * Kassier: [:layer_and_below_full, :contact_data, :finance]
    * Mitgliederdienst: [:layer_and_below_full, :contact_data]
  * Mitglieder
    * Mitglied: []
    * Ehrenmitglied: []
    * Begünstigt: []
    * Interessent*in: []
  * Kommission
    * Kommissionsleitung: [:group_full, :contact_data]
    * Kommissionsmitglied: []
* Hütte
  * Hütte
    * Hüttenwart*in: [:group_full]
    * Hüttenwartspartner*in: [:group_full]
    * Hüttenobmann: []
    * Mitarbeitende: []
    * Hüttenbetreuer*in: []
```

(Output of rake app:hitobito:roles)
