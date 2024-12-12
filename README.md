# Hitobito SAC CAS

This hitobito wagon defines the organization hierarchy with groups and roles of SAC CAS.

## Table of contents

- [Overview](./doc/README.md)
- [Abacus](./doc/abacus.md)
- [Organizational hierarchy](./doc/hierarchy.md)
- [Import](./doc/import.md)
- [Naming](./doc/naming.md)
- [OIDC](./doc/oidc-claims.md)

## Getting started

- [Developer](./doc/developer.md)

## Organization Hierarchy

<!-- roles:start -->
    * Schweizer Alpen-Club SAC
          * SAC Geschäftsstelle
            * Mitarbeiter*in (schreibend): 2FA [:layer_and_below_full, :read_all_people]  --  (Group::Geschaeftsstelle::Mitarbeiter)
            * Mitarbeiter*in (lesend): 2FA [:layer_and_below_read, :read_all_people]  --  (Group::Geschaeftsstelle::MitarbeiterLesend)
            * Administration: 2FA [:layer_and_below_full, :admin, :impersonation, :read_all_people]  --  (Group::Geschaeftsstelle::Admin)
            * Andere: 2FA [:layer_and_below_read, :read_all_people]  --  (Group::Geschaeftsstelle::Andere)
          * SAC Geschäftsleitung
            * Geschäftsführung: 2FA [:layer_and_below_read, :read_all_people]  --  (Group::Geschaeftsleitung::Geschaeftsfuehrung)
            * Ressortleitung: 2FA [:layer_and_below_read, :read_all_people]  --  (Group::Geschaeftsleitung::Ressortleitung)
            * Andere: 2FA [:layer_and_below_read, :read_all_people]  --  (Group::Geschaeftsleitung::Andere)
          * SAC Zentralvorstand
            * Präsidium: []  --  (Group::Zentralvorstand::Praesidium)
            * Mitglied: []  --  (Group::Zentralvorstand::Mitglied)
            * Andere: []  --  (Group::Zentralvorstand::Andere)
          * Kommission
            * Präsidium: []  --  (Group::Kommission::Praesidium)
            * Mitglied: []  --  (Group::Kommission::Mitglied)
            * Andere: []  --  (Group::Kommission::Andere)
          * Externe Kontakte
            * Kontakt: []  --  (Group::ExterneKontakte::Kontakt)
          * SAC-Tourenportal
            * Abonnent: []  --  (Group::AboTourenPortal::Abonnent)
            * Neuanmeldung: []  --  (Group::AboTourenPortal::Neuanmeldung)
            * Administration: []  --  (Group::AboTourenPortal::Admin)
            * Autor*in: []  --  (Group::AboTourenPortal::Autor)
            * Community: []  --  (Group::AboTourenPortal::Community)
            * Andere: []  --  (Group::AboTourenPortal::Andere)
            * Gratisabonnent: []  --  (Group::AboTourenPortal::Gratisabonnent)
          * SAC-Magazin
            * Autor*in: []  --  (Group::AboMagazine::Autor)
            * Andere: []  --  (Group::AboMagazine::Andere)
            * Übersetzer*in: []  --  (Group::AboMagazine::Uebersetzer)
          * AboMagazin
            * Abonnent: []  --  (Group::AboMagazin::Abonnent)
            * Neuanmeldung: []  --  (Group::AboMagazin::Neuanmeldung)
            * Gratisabonnent: []  --  (Group::AboMagazin::Gratisabonnent)
            * Andere: []  --  (Group::AboMagazin::Andere)
          * SAC/CAS Login
            * Basis Konto: []  --  (Group::AboBasicLogin::BasicLogin)
          * Ehrenmitglieder
            * Ehrenmitglied: []  --  (Group::Ehrenmitglieder::Ehrenmitglied)
          * Privathütten
            * Schreibrecht: [:group_and_below_full]  --  (Group::SacCasPrivathuetten::Schreibrecht)
          * Privathuette
            * Hüttenwart*in: []  --  (Group::SacCasPrivathuette::Huettenwart)
            * Hüttenchef*in: []  --  (Group::SacCasPrivathuette::Huettenchef)
            * Andere: []  --  (Group::SacCasPrivathuette::Andere)
          * Clubhütten
            * Schreibrecht: [:group_and_below_full]  --  (Group::SacCasClubhuetten::Schreibrecht)
          * Clubhuette
            * Hüttenwart*in: []  --  (Group::SacCasClubhuette::Huettenwart)
            * Hüttenchef*in: []  --  (Group::SacCasClubhuette::Huettenchef)
            * Andere: []  --  (Group::SacCasClubhuette::Andere)
          * SAC Kurskader
            * Kursleiter*in: []  --  (Group::SacCasKurskader::Kursleiter)
            * Klassenlehrer*in: []  --  (Group::SacCasKurskader::Klassenlehrer)
          * Verband & Organisation
            * Präsidium: []  --  (Group::SacCasVerband::Praesidium)
            * Mitglied: []  --  (Group::SacCasVerband::Mitglied)
            * Andere: []  --  (Group::SacCasVerband::Andere)
        * Sektion
        * Ortsgruppe
        * Global
          * Sektionsfunktionäre
            * Präsidium: []  --  (Group::SektionsFunktionaere::Praesidium)
            * Mitgliederverwaltung: []  --  (Group::SektionsFunktionaere::Mitgliederverwaltung)
            * Administration: 2FA [:layer_and_below_full]  --  (Group::SektionsFunktionaere::Administration)
            * Administration (nur lesend): 2FA [:layer_and_below_read]  --  (Group::SektionsFunktionaere::AdministrationReadOnly)
            * Finanzen: []  --  (Group::SektionsFunktionaere::Finanzen)
            * Redaktion: []  --  (Group::SektionsFunktionaere::Redaktion)
            * Hüttenobmann*frau: []  --  (Group::SektionsFunktionaere::Huettenobmann)
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsFunktionaere::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsFunktionaere::Schreibrecht)
            * Andere: []  --  (Group::SektionsFunktionaere::Andere)
            * Umweltbeauftragte*r: []  --  (Group::SektionsFunktionaere::Umweltbeauftragter)
            * Kulturbeauftragte*r: []  --  (Group::SektionsFunktionaere::Kulturbeauftragter)
          * Vorstand
            * Präsidium: [:group_read]  --  (Group::SektionsVorstand::Praesidium)
            * Mitglied: [:group_read]  --  (Group::SektionsVorstand::Mitglied)
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsVorstand::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsVorstand::Schreibrecht)
            * Andere: [:group_read]  --  (Group::SektionsVorstand::Andere)
          * Touren und Kurse
            * Tourenchef*in: [:group_read]  --  (Group::SektionsTourenUndKurseAllgemein::Tourenchef)
          * Touren und Kurse Sommer
            * Tourenchef*in: [:group_read]  --  (Group::SektionsTourenUndKurseSommer::Tourenchef)
          * Touren und Kurse Winter
            * Tourenchef*in: [:group_read]  --  (Group::SektionsTourenUndKurseWinter::Tourenchef)
          * Clubhütten
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsClubhuetten::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsClubhuetten::Schreibrecht)
          * Clubhuette
            * Hüttenwart*in: []  --  (Group::SektionsClubhuette::Huettenwart)
            * Hüttenchef*in: []  --  (Group::SektionsClubhuette::Huettenchef)
            * Andere: []  --  (Group::SektionsClubhuette::Andere)
          * Sektionshütten
            * Leserecht: [:group_and_below_read]  --  (Group::Sektionshuetten::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::Sektionshuetten::Schreibrecht)
          * Sektionshütte
            * Hüttenwart*in: []  --  (Group::Sektionshuette::Huettenwart)
            * Hüttenchef*in: []  --  (Group::Sektionshuette::Huettenchef)
            * Andere: []  --  (Group::Sektionshuette::Andere)
          * Kommissionen
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsKommissionen::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsKommissionen::Schreibrecht)
          * Kommission Hütten
            * Mitglied: [:group_read]  --  (Group::SektionsKommissionHuetten::Mitglied)
            * Präsidium: [:group_read]  --  (Group::SektionsKommissionHuetten::Praesidium)
            * Andere: [:group_read]  --  (Group::SektionsKommissionHuetten::Andere)
          * Kommission Touren
            * Mitglied: [:group_read]  --  (Group::SektionsKommissionTouren::Mitglied)
            * Präsidium: [:group_read]  --  (Group::SektionsKommissionTouren::Praesidium)
            * Andere: [:group_read]  --  (Group::SektionsKommissionTouren::Andere)
          * Kommission Umwelt und Kultur
            * Mitglied: [:group_read]  --  (Group::SektionsKommissionUmweltUndKultur::Mitglied)
            * Präsidium: [:group_read]  --  (Group::SektionsKommissionUmweltUndKultur::Praesidium)
            * Andere: [:group_read]  --  (Group::SektionsKommissionUmweltUndKultur::Andere)
          * Kommission
            * Leserecht: [:group_read]  --  (Group::SektionsKommission::Leserecht)
            * Schreibrecht: [:group_full]  --  (Group::SektionsKommission::Schreibrecht)
            * Mitglied: []  --  (Group::SektionsKommission::Mitglied)
            * Präsidium: []  --  (Group::SektionsKommission::Praesidium)
            * Andere: []  --  (Group::SektionsKommission::Andere)
          * Mitglieder
            * Mitglied (Stammsektion): []  --  (Group::SektionsMitglieder::Mitglied)
            * Mitglied (Zusatzsektion): []  --  (Group::SektionsMitglieder::MitgliedZusatzsektion)
            * Ehrenmitglied: []  --  (Group::SektionsMitglieder::Ehrenmitglied)
            * Begünstigt: []  --  (Group::SektionsMitglieder::Beguenstigt)
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsMitglieder::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsMitglieder::Schreibrecht)
          * Neuanmeldungen (zur Freigabe)
            * Neuanmeldung (Stammsektion): []  --  (Group::SektionsNeuanmeldungenSektion::Neuanmeldung)
            * Neuanmeldung (Zusatzsektion): []  --  (Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion)
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsNeuanmeldungenSektion::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsNeuanmeldungenSektion::Schreibrecht)
          * Neuanmeldungen
            * Neuanmeldung (Stammsektion): []  --  (Group::SektionsNeuanmeldungenNv::Neuanmeldung)
            * Neuanmeldung (Zusatzsektion): []  --  (Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion)
            * Leserecht: [:group_and_below_read]  --  (Group::SektionsNeuanmeldungenNv::Leserecht)
            * Schreibrecht: [:group_and_below_full]  --  (Group::SektionsNeuanmeldungenNv::Schreibrecht)
       
(Output of rake app:hitobito:roles)
<!-- roles:end -->
