## Version 2.4

* Der Changelog ist nur noch für Mitarbeiter der Geschäftsstelle verlinkt und aufrufbar (hitobito_sac_cas#1478)

## Version 2.3

*  Beim Empfänger-Export auf der Personenliste sind auch die strukturierte Adresse und die Anrede enthalten (hitobito_sac_cas#688)
* Neuer Personen-Export "Empfänger Familien" für den physischen Versand des Sektionsbulletins
* Eigene Berechtigung für Tab "Sicherheit" auf der Personenseite
* Für Personen mit aktiven Rollen "Mitglied (Stammsektion)" oder "Abonnent" werden Haupt-E-Mail, Namens- und Adress-Felder als Pflichtfelder definiert

## Version 2.2

* Die ID der nächsten Sektion, Ortsgruppe oder des Nationalverbands zu jeder Rolle wird jetzt als Claim im OIDC Userinfo Endpoint ausgegeben, wenn der with_roles Scope verwendet wird. (hitobito_sac_cas#389)
* Via Profil kann neu ein Mitglied-Ausweis angezeigt werden. Dieser enthält einen QR-Code zur Überprüfung der Mitgliederschaft der Person. (hitobito_sac_cas#70)
* Die Mitgliedernummer wird automatisch vergeben. Für den Import von bestehenden Mitgliedern kann die Mitgliedernummer manuell gesetzt werden. (hitobito_sac_cas#89)
* Die Mitgliedernummer wird in den CSV/XLSX Exporten mit ausgegeben. (hitobito_sac_cas#104)
* Berechnen der Beitragskategorie beim Erstellen von Mitglieder-/Neuanmeldungs-Rollen
* Neuanmeldungen bei Sektionen können verwaltet werden (annehmen, ablehnen) (hitobito_sac_cas#109)
* Einloggen mit Mitglied-Nr. oder Haupt-E-Mail-Adresse möglich (hitobito_sac_cas#119)
* Anmeldeformular zeigt für bestehende Mitglieder Beitragskategorie der Mitgliedschaft an (hitobito_sac_cas#119)
* Beim Etikettendruck wird bei jeder Person das Land immer gedruckt. Falls bei einer Person kein Land abgespeichert ist, wird Schweiz gedruckt (hitobito_sac_cas#426)
* Die Rollentypen werden nun alphabetisch sortiert im Auswahlmenü mit Ausnahme der Rolle "Andere" (hitobito_sac_cas#552)
* Analoger Mitgliederausweis PDF im neuen Design (hitobito_sac_cas#530)
