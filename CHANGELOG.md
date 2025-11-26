## Version unreleased

* Excel Export Wechsel Beitragskategorie (HIT-1321 / hitobito_sac_cas#2107)
* Excel Export Eingetretene Mitglieder (HIT-984 / hitobito_sac_cas#1665)
* Excel Export Mitgliederstatistik (HIT-1335 / hitobito_sac_cas#2061)
* Excel Export Jubilare (HIT-1191 / hitobito_sac_cas#2014)
* Neuer Gruppentyp Ressort (HIT-1011 / hitobito_sac_cas#2044)
* Rechnungsempfänger*in kann neu alle Familienmitglieder verwalten (HIT-1297 / hitobito_sac_cas#2002)
* Nächtliches Aufräumen von veralteten NV Neuanmeldungsrollen und Rechnungen (HIT-1337 / hitobito_sac_cas#2062)
* Auf Personenlisten werden die Spalten Austrittsdatum und -grund neu auch für zukünftige Austritte angezeigt (HIT-1322 / hitobito_sac_cas#2033)

## Version 2.6

* Deutsche Übersetzungen der Wagon Texte sind neu durch SAC selber übersetzbar auf transifex (HIT-1227 / hitobito_sac_cas#1889)
* Automatischer Beitragskategoriewechsel bei zutreffenden Mitgliedern im Rahmen des Jahresinkasso Jobs (hitobito_sac_cas#1890)
* Max. Kursteilnehmer wird berücksichtigt beim manuellen Anmelden von Teilnehmenden (HIT-1235 / hitobito_sac_cas#1928)
* Personen ohne aktive Rolle werden beim Login auf das Basis-Konto OnBoarding weitergeleitet (HIT-1208 / hitobito_sac_cas#1857)
* Bei Kursabsagen erhalten neu die Kursleitenden eine Absage E-Mail (HIT-1240 / hitobito_sac_cas#1925)
* Bei abgesagten Kursen ist das Bestätigen/Stornieren von Teilnahmen deaktiviert (HIT-1067 / hitobito_sac_cas#1922)
* Das "Die Alpen" Onboarding kann neu auch für Firmen durchgeführt werden (HIT-1243 / hitobito_sac_cas#1924)
* Beim Login mit einer unbestätigten E-Mail-Adresse wird das Bestätigungsemail automatisch erneut versendet (HIT-1201 / hitobito_sac_cas#1910)
* Bei Austritt eines Mitglieds aus SAC oder Zusatzsektion durch die Geschäftsstelle kann der Benutzer wählen ob Mitglied und Sektion per Email informiert werden soll (HIT-1116 / hitobito_sac_cas#1911)
* Auf der Person gibt es neu das Attribut "Werbesendungen", kann in Tabellen angezeigt und exportiert werden (HIT-1228 / hitobito_sac_cas#1909)
* Falls beim Kurszustandswechsel E-Mails ausgelöst werdern, müssen diese jetzt explizt bestätigt werden (HIT-1237 / hitobito_sac_cas#1921)
* Personen mit Sektionsfunktionär-Rollen "Präsidium", "Mitgliederverwaltung" und "Finanzen" können neu auch die Mitgliederstatistik herunterladen (HIT-1245 / hitobito_sac_cas#1912)
* Geschäftsstelle kann Stamm und Zusatzsektion tauschen (HIT-1220 / hitobito_sac_cas#1885)
* JSON:API gibt 404 zurück für Personen ohne aktive Rolle (HIT-1190 / hitobito_sac_cas#1858)
* Mitgliederausweis kann neu auch mit Osteuropäischen Zeichen gedruckt werden (HIT-1189 / hitobito_sac_cas#1870)
* Mails an Mitglied werden in der Sprache des Mitglieds versendet (HIT-1095, HIT-1112 / hitobito_sac_cas#1892, hitobito_sac_cas#1893)
* Effektive Ausbildungstage für Kursteilnehmende bearbeitbar (HIT-1175 / hitobito_sac_cas#1886)
* Beim SAC Austritt wird keine Qualifikationsprüfung mehr durchgeführt (HIT-1211 / hitobito_sac_cas#1894)
* Kurs Durchführungsort wird im Eckdatenblatt ausgegeben (HIT-1068 / hitobito_sac_cas#1887)
* Kursrechnung Texte werden in der Sprache des Teilnehmenden an Abacus übermittelt (HIT-1165 / hitobito_sac_cas#1896)
* Neuer Button "Mitgliederstatistik" auf Sektion/Ortsgruppe/SacCas (HIT-1231 / hitobito_sac_cas#1900)

## Version 2.5

* Tourenchef Rollen erhalten neu implizit Schreibrecht auf Mitglieder Gruppe (HIT-1206 / hitobito_sac_cas#1854)
* Jährlich wiederkehrende Kurse können kopiert werden (HIT-1148 / hitobito_sac_cas#1799)

## Version 2.4

* Der Changelog ist nur noch für Mitarbeiter der Geschäftsstelle verlinkt und aufrufbar (HIT-773 / hitobito_sac_cas#1478)
* Rollen mit Admin Berechtigungen können nur noch von Personen mit Admin Berechtigung bearbeitet, erstellt und gelöscht werden (hitobito#3127)
* Gekündigte Mitgliedschaften können reaktiviert werden (HIT-1034 / hitobito_sac_cas#1691)

## Version 2.3

* Beim Empfänger-Export auf der Personenliste sind auch die strukturierte Adresse und die Anrede enthalten (hitobito_sac_cas#688)
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
