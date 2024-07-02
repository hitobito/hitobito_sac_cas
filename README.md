# Hitobito SAC CAS

This hitobito wagon defines the organization hierarchy with groups and roles
of SAC CAS.

## Organization Hierarchy

```txt
    * Schweizer Alpen-Club SAC
      * SAC Geschäftsstelle
        * Mitarbeiter*in (schreibend): 2FA [:layer_and_below_full, :read_all_people]
        * Mitarbeiter*in (lesend): 2FA [:layer_and_below_read, :read_all_people]
        * Administration: 2FA [:layer_and_below_full, :admin, :impersonation, :read_all_people]
        * Andere: 2FA [:layer_and_below_read, :read_all_people]
      * SAC Geschäftsleitung
        * Geschäftsführung: 2FA [:layer_and_below_read, :read_all_people]
        * Ressortleitung: 2FA [:layer_and_below_read, :read_all_people]
        * Andere: 2FA [:layer_and_below_read, :read_all_people]
      * SAC Zentralvorstand
        * Präsidium: []
        * Mitglied: []
        * Andere: []
      * Kommission
        * Präsidium: []
        * Mitglied: []
        * Andere: []
      * Externe Kontakte
        * Kontakt: []
      * SAC Tourenportal
        * Abonnent: []
        * Neuanmeldung: []
        * Administration: []
        * Autor*in: []
        * Community: []
        * Andere: []
      * AboMagazin
        * Abonnent: []
        * Neuanmeldung: []
        * Autor*in: []
        * Andere: []
      * SAC/CAS Login
        * Basis Konto: []
      * Ehrenmitglieder
        * Ehrenmitglied: []
    * Sektion
    * Ortsgruppe
    * Global
      * Sektionsfunktionäre
        * Präsidium: [:layer_and_below_read]
        * Mitgliederverwaltung: 2FA [:layer_and_below_full]
        * Administration: 2FA [:layer_and_below_full]
        * Administration (nur lesend): 2FA [:layer_and_below_read]
        * Finanzen: []
        * Redaktion: []
        * Andere: []
      * Hütten
        * Hüttenobmann*frau: 2FA [:group_and_below_read]
        * Andere: [:group_read]
      * Hütte
        * Hüttenwart*in: [:group_read]
        * Hüttenchef*in: [:group_read]
        * Andere: [:group_read]
      * Touren und Kurse
        * Tourenchef*in Sommer: 2FA [:group_full, :layer_and_below_read]
        * Tourenchef*in Winter: 2FA [:group_full, :layer_and_below_read]
        * Tourenchef*in Klettern: 2FA [:group_full, :layer_and_below_read]
        * Tourenchef*in Senioren: 2FA [:group_full, :layer_and_below_read]
        * Tourenleiter*in (mit Qualifikation): []
        * Tourenleiter*in (ohne Qualifikation): []
        * JO-Chef*in: []
        * J+S Coach: []
        * Andere: []
      * Kommission
        * Präsidium: []
        * Mitglied: []
        * Andere: []
      * Vorstand
        * Präsidium: []
        * Mitglied: []
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
      * Externe Kontakte
        * Kontakt: []
```

(Output of rake app:hitobito:roles)
