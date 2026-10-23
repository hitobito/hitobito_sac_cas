# SurveyHero

Der SAC führt Kursumfragen mit [SurveyHero](https://www.surveyhero.com) durch. hitobito erstellt
pro Kurs einen eigenen Umfragelink und verschickt diesen nach Kursende an die Teilnehmenden.

## Konfiguration

Die Zugangsdaten werden über die ENV Variable `RAILS_SURVEY_HERO_CONFIG` gesetzt und landen in
`Settings.survey_hero.config`:

```
RAILS_SURVEY_HERO_CONFIG="user: 'username', password: 'api key'"
```

## Kurstyp und Kurs

Auf dem Kurstyp werden die SurveyHero Survey ID und Collector ID erfasst. Sie werden wie die
übrigen Kurstyp-Attribute auf die Kurse übertragen.

Auf dem Kurs steuert die Checkbox "Umfrage automatisch versenden" (`survey_auto_send`, standardmässig
aktiv) den Versand:

- Aktiv: der "Link Umfrage" ist nicht editierbar und wird beim Aktivieren geleert. hitobito erstellt
  ihn nach Kursende selbst.
- Inaktiv: der "Link Umfrage" wird manuell erfasst und die Umfrage manuell versendet.

## Versand

`Event::SurveyDispatchScheduleJob` läuft täglich um 08:00 und plant für jeden Kurs einen
`Event::SurveyDispatchJob` ein, welcher folgende Bedingungen erfüllt:

- Ist im Status "Bereit zur Durchführung" oder "Abgeschlossen"
- Hat die Checkbox "Umfrage automatisch versenden" aktiv
- Hat eine Survey ID, aber noch keinen "Link Umfrage"
- Hatte den letzten Kurstag heute oder in den letzten 7 Tagen

`Events::Courses::SurveyDispatcher` erstellt pro Kurs den Umfragelink (siehe [API](#api)),
speichert ihn als "Link Umfrage" und verschickt die Umfrage-E-Mail an alle Teilnehmenden in den
Status "Bestätigt", "Aufgeboten" und "Teilgenommen". Ein Kurs mit "Link Umfrage" gilt als erledigt
und wird nicht erneut versendet.

Sind Survey ID oder Collector ID ungültig oder liefert SurveyHero keinen Umfragelink
(`Client::Error`), wird sofort ein Fehler mit Kategorie "kursumfragen" im Log auf dem Kurs erfasst.
Da der Kurs weiterhin keinen "Link Umfrage" hat, wird er an den folgenden Tagen erneut versucht und
der Logeintrag jeweils ersetzt.

## API

Die Anbindung an das [SurveyHero API](https://developer.surveyhero.com/api/) liegt im Namespace
`Events::Courses::SurveyHero`.

`Client` sendet die Requests als JSON mit Basic Auth aus `Settings.survey_hero.config`.
`#copy_collector` kopiert einen Collector einer Umfrage und gibt den Umfragelink des neuen Collectors
zurück. Fehlermeldungen des API werden als Message der `RestClient` Exception übernommen. Bei
unbekannter oder nicht zugänglicher Umfrage bzw. Collector (404, 403) sowie bei einer Antwort ohne
Link wird `Client::Error` geworfen.

`CourseLink` erstellt den Umfragelink eines Kurses. Dazu kopiert er den Collector aus Survey ID und
Collector ID des Kurses unter dem Namen `SAC Kursumfrage: <Kursname> (<Kursnummer>)` und hängt an
dessen Link folgende Parameter an:

- `course-id`: Kursnummer
- `coursename`: Kursname in der Kurssprache, bei zweisprachigen Kursen deutsch
- `event-start`, `event-finish`: erster und letzter Kurstag im Format `dd.mm.yyyy`
