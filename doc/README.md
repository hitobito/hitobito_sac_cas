# SAC/CAS

## Beitragskategorie

Die Beitragskategorie definiert auf der Mitgliedschaft wie hoch die jährlichen Kosten ausfallen.

Es gibt dabei drei Kategorien: Einzel, Jugend, Familie

### Einzel

Für Einzel-Personen ab 22 Jahren

### Jugend

Für Jugendliche von 6 bis 21 Jahren

### Familie

Für Familien mit max. 2 Erwachsenen ab 22 Jahren sowie beliebig viele Kinder von 6 bis 17 Jahren

### Hitobito

Die Beitragskategorie wird beim Erstellen einer **Mitglied** Rolle berechnet und auf dieser hinterlegt. Sie kann bei einer bestehenden Rolle nicht geändert werden (attr_readonly). Ist eine Wechsel der Beitragskategorie nötig, so muss die aktuelle Rolle terminiert und eine neue Rolle erstellt werden. Dies stellt sicher das der Beitragskategorie-Wechsel in der History der Person ersichtlich und dokumentiert ist.

## Familie

-   Haushalt + Beitragskategorie

## Neuanmeldungen

Jede Sektion besitzt die Untergruppe **Neuanmeldungen**. In dieser Gruppe landen Personen welche zu einer Sektion beitreten möchten. Will eine Sektion die Neuanmeldungen manuell prüfen und freigeben, besitzt diese zusätzlich die Untergruppe **Neuanmeldungen (zur Freigabe)**. Auf dieser Gruppe gibt es spezifische Actions um durch die Mitgliederverwaltung der Sektion eine Person freizugeben oder abzulehnen. Wir die Person freigegeben, landet diese in der Gruppe **Neuanmeldungen** und somit im Standard-Workflow für neue Mitglieder.
Sobald die offene Mitgliederbeitragsrechnung bezahlt wurde, wird die Rolle der Person in **Neuanmeldungen** durch eine aktive Mitglieder-Rolle in der Sektions-Untergruppe **Mitglieder** ersetzt.

### Rollen

-   `Group::SektionsNeuanmeldungenSektion::Neuanmeldung` (Stammsektion)
-   `Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion`
-   `Group::SektionsNeuanmeldungenNv::Neuanmeldung` (Stammsektion)
-   `Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion`

## Rollen

### Aktive Mitgliederrollen

Als Mitgliederrollen zählen:

-   `Group::SektionsMitglieder::Mitglied` (Stammsektion)
-   `Group::SektionsMitglieder::MitgliedZusatzsektion`

#### Validierungen

-   Eine Person kann nur eine aktive Stammsektion Mitglieder-Rolle haben
-   Um eine Zusatzsektion Rolle zu haben muss eine aktive Stammsektion Rolle vorhanden sein

#### Berechtigungen

-   Die Hauptgruppe kann nicht geändert werden, solange die aktuelle Primärgruppe via einer Mitgliederrolle definiert ist.
