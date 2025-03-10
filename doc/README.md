# SAC/CAS

[`Naming`](naming.md)

## Beitragskategorie

Die Beitragskategorie definiert auf der Mitgliedschaft einer Sektion wie hoch die jährlichen Kosten ausfallen.

Es gibt dabei drei Kategorien: Einzel, Jugend, Familie (adult, youth, family)

- Einzel: Für Einzel-Personen ab 22 Jahren
- Jugend: Für Jugendliche von 6 bis 21 Jahren
- Familie: Für Familien mit max. 2 Erwachsenen ab 22 Jahren sowie beliebig viele Kinder von 6 bis 17 Jahren die im selben Haushalt wohnen.

### Hitobito

Die Beitragskategorie wird beim Erstellen einer **Mitglied** Rolle berechnet und auf dieser hinterlegt. Sie kann bei einer bestehenden Rolle nicht geändert werden (attr_readonly). Ist eine Wechsel der Beitragskategorie nötig, so muss die aktuelle Rolle terminiert und eine neue Rolle erstellt werden. Dies stellt sicher das der Beitragskategorie-Wechsel in der History der Person ersichtlich und dokumentiert ist.

## SAC Familie

In Hitobito ist eine Familie mit dem `Household` abgebildet. Alle Personen im `Household` haben auf ihrer `Mitglied` Rolle die Beitragskategorie `'family'`.

Wenn Personen dem `Household` hinzugefügt werden, werden ihre `Mitglied` Rollen per Vortag gelöscht und neue erstellt  mit Beitragskagetorie `'family'`.

Beim Entfernen von Personen aus dem `Household` werden deren `Mitglied` sowie `MitgliedZusatzsektion` Rollen mit Beitragskategorie `'family'` per Vortag gelöscht und entsprechende neue Rollen erstellt mit Beitragskategorie dem Alter entsprechend `'adult'` oder `'youth'`.

Personen werden zuerst zu einem Haushalt hinzugefügt und müssen danach das Beitragskategorie Feld auf ihrer Mitgliedsrolle angepasst bekommen.

### Validierungen

- Mindestens eine Person des Haushalts benötigt eine Mitgliedschaftsrolle in einer Sektion.
- Die Personen dürfen noch keine Rolle mit Beitragskategorie Familie haben.

### Specs

Zum Einrichten der Testdaten, gibt es folgende Helfer:
Die `familienmitglied` Fixtures people und roles sowie Fabricators wie person_with_role.
Die Familie kann mit der Household Klasse erstellt werden.

Ein Beispiel zum Anlegen einer Familie mit Fabricator gibt es unter [`join_base_spec.rb`](https://github.com/hitobito/hitobito_sac_cas/blob/master/spec/models/memberships/join_base_spec.rb) und [`household_spec.rb`](https://github.com/hitobito/hitobito_sac_cas/blob/master/spec/models/household_spec.rb)

## Neuanmeldungen

Jede Sektion besitzt die Untergruppe **Neuanmeldungen**. In dieser Gruppe landen Personen welche zu einer Sektion beitreten möchten. Will eine Sektion die Neuanmeldungen manuell prüfen und freigeben, besitzt diese zusätzlich die Untergruppe **Neuanmeldungen (zur Freigabe)**. Auf dieser Gruppe gibt es spezifische Actions um durch die Mitgliederverwaltung der Sektion eine Person freizugeben oder abzulehnen. Wir die Person freigegeben, landet diese in der Gruppe **Neuanmeldungen** und somit im Standard-Workflow für neue Mitglieder.
Sobald die offene Mitgliederbeitragsrechnung bezahlt wurde, wird die Rolle der Person in **Neuanmeldungen** durch eine aktive Mitglieder-Rolle in der Sektions-Untergruppe **Mitglieder** ersetzt.

### Rollen

- `Group::SektionsNeuanmeldungenSektion::Neuanmeldung` (Stammsektion)
- `Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion`
- `Group::SektionsNeuanmeldungenNv::Neuanmeldung` (Stammsektion)
- `Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion`

## Rollen

### Aktive Mitgliederrollen

Als Mitgliederrollen zählen:

- `Group::SektionsMitglieder::Mitglied` (Stammsektion)
- `Group::SektionsMitglieder::MitgliedZusatzsektion`

#### Validierungen

- Eine Person kann nur eine aktive Stammsektion Mitglieder-Rolle haben
- Um eine Zusatzsektion Rolle zu haben muss eine aktive Stammsektion Rolle vorhanden sein

### Austritt

Ein Mitglied hat die Möglichkeit unter Person / Verlauf seine Mitgliedschaft zu kündigen (Austritt). Dazu gibt es auf der Rolle ein boolean Flag :terminated. Die Basis-Funktionalität dazu ist bereits im Core definiert.

## Abacus

[Schnittstellen Dokumentation Abacus](./abacus.md)
