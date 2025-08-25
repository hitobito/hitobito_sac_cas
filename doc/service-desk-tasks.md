## Häuffige Service Desk Aufgaben

### Reaktivieren

"Reaktivieren" kann verschiedenes heissen:

- Abgelaufene Rolle verlängern, z.B. bis Ende Jahr oder für in 2 Monaten
- Gekündigte Rolle reaktiveren: Kündigung entfernen und ev. verlängern (`terminated` flag und `termination_reason_id` entfernen, `end_on` anpassen)
- Im Falle einer abgelaufenen oder in der Vergangenheit gekündigten Familienmitgliedschaft muss auch die Familie wiederhergestellt werden. Siehe **Familienmitgliedschaft wiederherstellen** weiter unten.

### Gekündigte Mitgliedschaft reaktivieren

Es ist eine "Undo" Funktionalität implementiert auf Basis der paper_trail versions. Diese setzt voraus, dass das Attribut `mutation_id` auf der version gesetzt ist. Bei Kündigungen welche vorgenommen wurden bevor das `mutation_id` implementiert war, fehlt der `mutation_id` Wert, im Frontend wird in diesem Fall im flash eine entsprechende Fehlermeldung ausgegeben.

Das `rails cli` script implementiert eine Funktion, mit welcher auf gekündigten Einzel- und Jugendmitgliedschaftsrollen die `mutation_id` automatisch ergänzen kann. Bei Familienmitgliedschaften muss dies manuell gemacht werden.

Ich verwende jeweils `SecureRandom.uuid` um eine neue `mutation_id` zu generieren (bei allen Familienmitgliedern muss derselbe Wert gesetzt werden)

### Familienmitgliedschaft wiederherstellen

Eine Familie ist bei SAC an eine Mitgliedschaft gekoppelt. Wenn eine Familienmitgliedschaft gekündigt wird oder wenn sie einfach nicht rechtzeitig verlängert wird, dann wird die Familie vom `People::SacMemberships::DestroyHouseholdsForInactiveMembershipsJob` automatisch aufgelöst (der `household_key` wird auf den Personen entfernt).

Es gibt Situationen, in welchen die Familie und die Mitgliedschaft wiederhergestellt werden muss, z.B. wenn die Mitgliedschaft abgelaufen ist und die Familie aufgelöst wurde, weil die Zahlung der Mitgliedschaftsrechnung aus irgendwelchen Gründen nicht korrekt verbucht werden konnte.

Vorgehen:

1. Originale Stammsektionsrollen finden: Z.B. auf einer Person die relevante Stammsektionsrolle eruieren. Auf dieser ist als `family_id` der originale `household_key` der Person gespeichert (wird beim erstellen der Rolle eingetragen). Nun lassen sich alle dazugehörigen Rollen aller Familienmitglieder finden mit `Role.unscoped.where(family_id:)`. Falls pro Person mehrere Stammsektionsrollen gefunden werden, muss jeweils die neueste genommen werden.
2. Familie wiederherstellen indem auf allen Familienmitgliedern der `household_key` anhand der `family_id` der Stammsektionsrolle wieder gesetzt wird. Auf einer Person muss `sac_family_main_person = true` gesetzt werden. Ev. kann über das papertrail log herausgefunden werden, welche Person die Hauptperson war, ansonsten nehme ich die Person welche im Ticket erwähnt war.
3. Stammsektionsrollen wiederherstellen: `end_on` auf einen Wert in der Zukunft setzen (z.B. Ende Jahr, oder in 2 Monaten, im Zweifelsfall im Service Ticket nachfragen).
