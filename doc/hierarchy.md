# Organizational hierarchy

The output of `rake app:hitobito:roles` will show you the roles hierarchy:

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
        * Präsidium: []
        * Mitgliederverwaltung: []
        * Administration: 2FA [:layer_and_below_full]
        * Administration (nur lesend): 2FA [:layer_and_below_read]
        * Finanzen: []
        * Redaktion: []
        * Hüttenobmann*frau: []
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
        * Andere: []
      * Vorstand
        * Präsidium: [:group_read]
        * Mitglied: [:group_read]
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
        * Andere: [:group_read]
      * Touren und Kurse
        * Tourenleiter*in (mit Qualifikation): []
        * Tourenleiter*in (ohne Qualifikation): []
        * JO-Chef*in: []
        * J+S Coach: []
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
      * Touren und Kurse Sommer
        * Tourenchef*in: [:group_read]
      * Touren und Kurse Winter
        * Tourenchef*in: [:group_read]
      * Clubhütten
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
      * Clubhuette
        * Hüttenwart*in: []
        * Hüttenchef*in: []
        * Andere: []
      * Sektionshütten
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
      * Sektionshütte
        * Hüttenwart*in: []
        * Hüttenchef*in: []
        * Andere: []
      * Kommissionen
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
      * Kommission Hütten
        * Mitglied: [:group_read]
        * Präsidium: [:group_read]
        * Andere: [:group_read]
      * Kommission Touren
        * Mitglied: [:group_read]
        * Präsidium: [:group_read]
        * Andere: [:group_read]
      * Kommission Umwelt und Kultur
        * Mitglied: [:group_read]
        * Präsidium: [:group_read]
        * Andere: [:group_read]
      * Mitglieder
        * Mitglied (Stammsektion): []
        * Mitglied (Zusatzsektion): []
        * Ehrenmitglied: []
        * Begünstigt: []
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
      * Neuanmeldungen (zur Freigabe)
        * Neuanmeldung (Stammsektion): []
        * Neuanmeldung (Zusatzsektion): []
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
      * Neuanmeldungen
        * Neuanmeldung (Stammsektion): []
        * Neuanmeldung (Zusatzsektion): []
        * Leserecht: [:group_and_below_read]
        * Schreibrecht: [:group_and_below_full]
```
