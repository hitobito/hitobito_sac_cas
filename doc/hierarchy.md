# Organizational hierarchy

The output of `rake app:hitobito:roles[true]` will show you the roles hierarchy:

```txt
    * Schweizer Alpen-Club SAC
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
      * SAC Abos (ohne Newsletter)
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
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SacCasPrivathuetten::Schreibrecht)
      * Privathuette
        * Hüttenwart*in: []  --  (Group::SacCasPrivathuette::Huettenwart)
        * Hüttenchef*in: []  --  (Group::SacCasPrivathuette::Huettenchef)
        * Andere: []  --  (Group::SacCasPrivathuette::Andere)
      * Clubhütten
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SacCasClubhuetten::Schreibrecht)
      * Clubhuette
        * Hüttenwart*in: []  --  (Group::SacCasClubhuette::Huettenwart)
        * Hüttenchef*in: []  --  (Group::SacCasClubhuette::Huettenchef)
        * Andere: []  --  (Group::SacCasClubhuette::Andere)
      * SAC Kurskader
        * Kursleiter*in: []  --  (Group::SacCasKurskader::Kursleiter)
        * Klassenlehrer*in: []  --  (Group::SacCasKurskader::Klassenlehrer)
        * Kursleiter*in (Aspirant): []  --  (Group::SacCasKurskader::KursleiterAspirant)
        * Klassenlehrer*in (Aspirant): []  --  (Group::SacCasKurskader::KlassenlehrerAspirant)
      * Verbände & Organisationen
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
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsFunktionaere::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsFunktionaere::Schreibrecht)
        * Andere: []  --  (Group::SektionsFunktionaere::Andere)
        * Umweltbeauftragte*r: []  --  (Group::SektionsFunktionaere::Umweltbeauftragter)
        * Kulturbeauftragte*r: []  --  (Group::SektionsFunktionaere::Kulturbeauftragter)
      * Vorstand
        * Präsidium: [:group_read]  --  (Group::SektionsVorstand::Praesidium)
        * Mitglied: [:group_read]  --  (Group::SektionsVorstand::Mitglied)
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsVorstand::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsVorstand::Schreibrecht)
        * Andere: [:group_read]  --  (Group::SektionsVorstand::Andere)
      * Touren und Kurse
        * Tourenleiter*in (mit Qualifikation): [:layer_events_full]  --  (Group::SektionsTourenUndKurse::Tourenleiter)
        * Tourenleiter*in (ohne Qualifikation): [:layer_events_full]  --  (Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation)
        * Tourenchef*in: 2FA [:layer_and_below_read, :layer_events_full, :layer_mitglieder_full, :layer_touren_und_kurse_full]  --  (Group::SektionsTourenUndKurse::Tourenchef)
        * Tourenchef*in Sommer: 2FA [:layer_and_below_read, :layer_events_full, :layer_mitglieder_full, :layer_touren_und_kurse_full]  --  (Group::SektionsTourenUndKurse::TourenchefSommer)
        * Tourenchef*in Winter: 2FA [:layer_and_below_read, :layer_events_full, :layer_mitglieder_full, :layer_touren_und_kurse_full]  --  (Group::SektionsTourenUndKurse::TourenchefWinter)
        * KiBe-Chef*in: []  --  (Group::SektionsTourenUndKurse::KibeChef)
        * FaBe-Chef*in: []  --  (Group::SektionsTourenUndKurse::FabeChef)
        * JO-Chef*in: []  --  (Group::SektionsTourenUndKurse::JoChef)
        * J+S Coach: []  --  (Group::SektionsTourenUndKurse::JsCoach)
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsTourenUndKurse::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsTourenUndKurse::Schreibrecht)
      * Freigabekomitee
        * Prüfer*in: [:group_read]  --  (Group::FreigabeKomitee::Pruefer)
      * Clubhütten
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsClubhuetten::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsClubhuetten::Schreibrecht)
      * Clubhütte
        * Hüttenwart*in: []  --  (Group::SektionsClubhuette::Huettenwart)
        * Hüttenchef*in: []  --  (Group::SektionsClubhuette::Huettenchef)
        * Andere: []  --  (Group::SektionsClubhuette::Andere)
      * Sektionshütten
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::Sektionshuetten::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::Sektionshuetten::Schreibrecht)
      * Sektionshütte
        * Hüttenwart*in: []  --  (Group::Sektionshuette::Huettenwart)
        * Hüttenchef*in: []  --  (Group::Sektionshuette::Huettenchef)
        * Andere: []  --  (Group::Sektionshuette::Andere)
      * Kommissionen
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsKommissionen::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsKommissionen::Schreibrecht)
      * Kommission Hütten
        * Mitglied: [:group_read]  --  (Group::SektionsKommissionHuetten::Mitglied)
        * Präsidium: [:group_read]  --  (Group::SektionsKommissionHuetten::Praesidium)
        * Andere: [:group_read]  --  (Group::SektionsKommissionHuetten::Andere)
      * Kommission Touren
        * Mitglied: [:group_read, :layer_events_full]  --  (Group::SektionsKommissionTouren::Mitglied)
        * Präsidium: [:group_read, :layer_events_full]  --  (Group::SektionsKommissionTouren::Praesidium)
        * Andere: [:group_read]  --  (Group::SektionsKommissionTouren::Andere)
      * Kommission Umwelt und Kultur
        * Mitglied: [:group_read]  --  (Group::SektionsKommissionUmweltUndKultur::Mitglied)
        * Präsidium: [:group_read]  --  (Group::SektionsKommissionUmweltUndKultur::Praesidium)
        * Andere: [:group_read]  --  (Group::SektionsKommissionUmweltUndKultur::Andere)
      * Kommission
        * Leserecht: 2FA [:group_read]  --  (Group::SektionsKommission::Leserecht)
        * Schreibrecht: 2FA [:group_full]  --  (Group::SektionsKommission::Schreibrecht)
        * Mitglied: []  --  (Group::SektionsKommission::Mitglied)
        * Präsidium: []  --  (Group::SektionsKommission::Praesidium)
        * Andere: []  --  (Group::SektionsKommission::Andere)
      * Ressorts
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsRessorts::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsRessorts::Schreibrecht)
      * Ressort
        * Mitglied: []  --  (Group::SektionsRessort::Mitglied)
        * Leitung: []  --  (Group::SektionsRessort::Leitung)
        * Andere: []  --  (Group::SektionsRessort::Andere)
      * Mitglieder
        * Mitglied (Stammsektion): []  --  (Group::SektionsMitglieder::Mitglied)
        * Mitglied (Zusatzsektion): []  --  (Group::SektionsMitglieder::MitgliedZusatzsektion)
        * Ehrenmitglied: []  --  (Group::SektionsMitglieder::Ehrenmitglied)
        * Begünstigt: []  --  (Group::SektionsMitglieder::Beguenstigt)
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsMitglieder::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsMitglieder::Schreibrecht)
      * Neuanmeldungen (zur Freigabe)
        * Neuanmeldung (Stammsektion): []  --  (Group::SektionsNeuanmeldungenSektion::Neuanmeldung)
        * Neuanmeldung (Zusatzsektion): []  --  (Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion)
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsNeuanmeldungenSektion::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsNeuanmeldungenSektion::Schreibrecht)
      * Neuanmeldungen
        * Neuanmeldung (Stammsektion): []  --  (Group::SektionsNeuanmeldungenNv::Neuanmeldung)
        * Neuanmeldung (Zusatzsektion): []  --  (Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion)
        * Leserecht: 2FA [:group_and_below_read]  --  (Group::SektionsNeuanmeldungenNv::Leserecht)
        * Schreibrecht: 2FA [:group_and_below_full]  --  (Group::SektionsNeuanmeldungenNv::Schreibrecht)
```
