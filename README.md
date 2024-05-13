# Hitobito SAC CAS

This hitobito wagon defines the organization hierarchy with groups and roles
of SAC CAS.


## Organization Hierarchy

```
    * Schweizer Alpen-Club SAC
      * Geschäftsstelle
        * Mitarbeiter*in (schreibend): 2FA [:layer_and_below_full, :read_all_people]
        * Mitarbeiter*in (lesend): 2FA [:layer_and_below_read, :read_all_people]
        * Admin: 2FA [:layer_and_below_full, :admin, :impersonation, :read_all_people]
      * Ehrenmitglieder
        * Ehrenmitglied: []
      * Externe Kontakte
        * Kontakt: []
      * Touren-Portal
        * Abonnent: []
        * Neuanmeldung: []
      * AboMagazin
        * Abonnent: []
        * Neuanmeldung: []
      * SAC/CAS Login
        * Basis Konto: []
    * Sektion, Ortsgruppe
      * Funktionäre
        * Präsidium: []
        * Mitgliederverwaltung: 2FA [:layer_and_below_full]
        * Administration: 2FA [:layer_and_below_full]
        * Administration (nur lesend): 2FA [:layer_and_below_read]
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
        * Tourenchef*in Sommer: 2FA [:group_full]
        * Tourenchef*in Winter: 2FA [:group_full]
        * Tourenchef*in Klettern: 2FA [:group_full]
        * Tourenchef*in Senioren: 2FA [:group_full]
        * Tourenleiter*in: []
      * Hüttenkommission
        * Hüttenobmann*frau: 2FA [:group_and_below_read]
        * Andere: [:group_read]
      * Externe Kontakte
        * Kontakt: []
```

(Output of rake app:hitobito:roles)
