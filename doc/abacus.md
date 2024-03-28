# Abacus

Abacus wird beim SAC verwendet, um Rechnungen zu verarbeiten. Dazu werden Rechnungen und zugehörige Personen von Hitobito in Abacus über ein JSON REST API erstellt.

## Kontakte

Die Kontakte der Betreiberfirma von Abacus sind im [Puzzle Wiki](https://wiki.puzzle.ch/Hitobito/KontaktePartner) geführt.

## Desktop Client

Um via Desktop Client auf Abacus zuzugreifen, muss erst der [Abaclient](https://downloads.abacus.ch/downloads/abaclient) heruntergeladen werden.

Persönliche Zugänge werden vom SAC erstellt. Für die 2FA wird zum Login die [Abacus Access App](https://play.google.com/store/apps/details?id=ch.abacus.access&hl=de_CH) benötigt.

Über die [SAC Abacus Platform](https://sac-cas.erp.abraxas-apps.ch) kann via *ERP* ein Link heruntergeladen werden, welcher den lokalen Abaclient mit den im Web eingegebenen Credentials startet.

## API

Die Dokumentation findet sich auf dem [Abacus API Hub](https://apihub.abacus.ch/general).

Unter `app/domain/invoice/abacus/client.rb` befindet sich der Client, welcher mit Abacus kommuniziert.
