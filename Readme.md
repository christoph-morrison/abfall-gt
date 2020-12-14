# Müllabfuhr-REST-API für die Stadt Gütersloh

## Intro

*Als Bewohnender der Stadt Gütersloh möchte ich die nächsten Termine zur Müllabfuhr in meiner Hausautomatisierung automatisiert abfragen können.*

Die Stadt Gütersloh versucht sich ja seit längerer Zeit als [Smart City](https://www.digitaler-aufbruch-guetersloh.de/) - und oft genug besteht Digitalisierung nur aus einer Smart-Phone-App oder iCal-Dateien, die die alten PDF-Dateien (aus der Digitalisierung 1.0) als Format ersetzt haben.

![Das Internet ist für uns alle Neuland!](assets/neuland.gif)

Ich finde beides nicht sehr befriedigend, denn beide Quellen sind wirklich nur die elektronische Repräsentation der alten Drucke. D.h. insbesondere, dass z.B. eine Anfrage wie "Gibt es diese Woche eine Abholung?" nicht ad hoc beantwortet werden kann, da beide Quellen immer **alle** verfügbaren Termine inkl. die der Vergangenheit für das laufende Jahr (und ggf. noch für das vergangene bzw. kommende Jahr) beinhalten.

Es stellt sich außerdem die Frage, inwiefern es nötig ist, dass die Daten an ein privates Unternehmen - anstatt von der Kommune direkt an die Bürger - geliefert werden, die die Erstellung dieser Daten mit ihren Abgaben, Gebühren und Steuern finanziert haben.

Eine API sollte folgende Abfragemöglichkeiten bieten:
1. Abfrage aller unterstüzten Orte
1. Abfrage aller verfügbaren Straßen
1. Abfrage alle Abholungstermine einer Straße
    1. gefiltert nach einem Zeitraum
    1. gefiltert nach einer Müllart (z.B. Altpapier oder Kompost)
1. Abfrage des nächsten Abholungstermins
    1. einer Straße
    1. einer bestimmten Müllart
    1. insgesamt
1. Abfrage der betroffenen Straßen des nächsten Abholungstermins

## Meine API

### Umfang
Um meinen Bedarf an einer API zu befriedigen, habe ich als Fingerübung selbst eine geschrieben. Die Daten werden aus den iCal-Dateien bezogen (da ich die API der App zum Zeitpunkt meiner Umsetzung noch nicht kannte), mit Perl extrahiert und in einer MariaDB-Instanz gespeichert. 

Die Daten werden einmal monatlich aktualisiert, immer zum Ersten des Monats.

Bis dato erfüllt sie die Anforderungen 1 bis 4 vollständig.

### Dokumentation der Endpunkte

Folgt.

### Datenschutz

Der REST-Server sowie die Datenbank loggen nichts.

## Quellen
## REST-API der Abfall-App

Die REST-API der RegioIT (mit mitmproxy aus der iOS-App abgeschnorchelt) liefert im Prinzip all die Daten, die auch in den iCal-Dateien vorhanden sind.

### Endpunkte

#### Metadaten

##### Appdata
- [/appdata](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/appdata)
- Liefert Meta-Informationen über den Datenbestand. Welche Uhrzeit aber 25:00 sein soll, hätte ich doch gerne erklärt ``(>ლ)``.

##### Login zur Datenpflege
- [/login.jsf](https://gt2-abfallapp.regioit.de/abfall-app-gt2/login.jsf)
- Bingo.
- XSS in das Login-Formular nicht trivial möglich.

##### Servicetexte
- [/orte/445739/service](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/texte/ort/445739/service)
- Servicetexte der App

##### Verweis auf den Servicebereich der Stadtreinigung
- [/texte/ort/Gütersloh/service](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/texte/ort/G%C3%BCtersloh/service) 

##### Impressum
- [/ort/Gütersloh/impressum](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/texte/ort/G%C3%BCtersloh/impressum)
- Impressum der zuständigen, kommunalen Stelle.

##### Abfallkategorien
- [/kategorien](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/kategorien)
- Listet alle Abholkategorien auf

##### Aktuelle Meldungen
- [/text/aktuelles?ort=Gütersloh](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/texte/aktuelles?ort=G%C3%BCtersloh)
- Aktuelle Meldungen

##### Preise
- [/texte/ort/Gütersloh/preise](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/texte/ort/G%C3%BCtersloh/preise)
- Preisinformationen als HTML-Text, unstrukturiert

##### Entsorgungs-Glossar
- [/stoffe](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/stoffe)
- Glossar über Abfallstoffe, Informationen zum Entsorgungsort und zur -art. 

#### Stationäre Sammlung
##### Entsorgungsstandorte
- [/standorte/standortarten](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/standorte/standortarten)
- Enthält Informationen über die verschiedenen Standortarten

##### Standorte
- [/standorte](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/standorte)
- Liste aller stationären Entsorgungsmöglichkeiten, z.B. Altkleider- oder Papiercontainer, inkl. Geo-Koordinaten.

##### Öffnungszeiten der mobilen Standorte
- [/standorte/10022/mobiltermine](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/standorte/10022/mobiltermine)
- Zum Beispiel die Annahmezeiten des Schadstoffmobils an einem bestimmten Termin.

#### Abholungsbezogene Informationen
##### Liste untersützter Orte
- [/orte](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/orte/)
- In Gütersloh uninteressant, da die App nur die Termine für Gütersloh enthält. Gütersloh hat die ID ``445739``.

##### Verzeichnis der Straßen im Ort
- [/orte/445739/strassen](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/orte/445739/strassen)
- Liefert eine Liste aller Straßen in Gütersloh (in CAPS und abgekürzt ``(>ლ)``) mit ihrer ID zurück, der ~~Tulpenweg~~TULPENWEG hat z.B. die ID ``446868``.

##### Straße abfragen
- [/orte/Gütersloh/strassen?q=TULPENWEG](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/orte/G%C3%BCtersloh/strassen?q=TULPENWEG)
- Fragt den Ort nach einer Straße ab. Groß- und Kleinschreibung wird nicht [beachtet](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/orte/G%C3%BCtersloh/strassen?q=tUlPEnWEG)!

##### Abholbezirke
- [/bezirke](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/bezirke)
- Liefert eine Liste aller Abholbezirke. Diese sind gruppiert nach
    - `name`, Bezirks-ID, z.B. `A` oder `I`
    - `id`, Straßen-ID, z.B. `446868`
    - `fraktionId`, Abholtyp, z.B. `3`

##### Metadaten einer Straße 
- [/strassen/446868](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/strassen/446868/)
- Enthält der Namen der Straße, erneut in CAPS und abgekürzt, und den Ort. Der Zugriff auf Straßen-ID außerhalb des geographischen Bereichs der App, z.B. Stadt Gütersloh, ist nicht möglich. Es scheint aber, dass die ID bundesweit eindeutig ist, da im Kreis Gütersloh / Warendorf die ID, die in der Stadt Gütersloh vergeben sind, nicht erneut vorkommen. Das lässt auf eine Datenbank für alle von RegioIT unterstützte Orte schließen - wieso gibt es dort keine REST-API für das gesamte Bundesgebiet?

##### Fraktionen (einer Straße)
- [/fraktionen](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/fraktionen)
- [/strassen/446868/fraktionen](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/strassen/446868/fraktionen)
- "Fraktionen" scheinen im internen Sprachgebrauch die Müllart zu sein, die abgeholt werden. So steht die Fraktion 3 für Altpapier. Dieser Endpunkt liefert alle Fraktionen  (für eine spezifische Straße) zurück, inkl. einer Icon-ID und einem RGB-Farbcode für die Darstellung in der App.

##### Termine einer Straße
- [/strassen/446868/termine](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/strassen/446868/termine)
- Liefert sämtliche Abholungstermine einer Straße für jede Fraktion kombiniert in einem Endpunkt.

## iCal-Dateien

RegioIT bietet außerdem die Möglichkeit [iCal-Dateien](https://abfallkalender.regioit.de/kalender-gt/) (und PDF) zu beziehen. Die Jahresauswahl scheint zu diesem Zeitpunkt (Anfang Dezember 2020) keinen nennenswerten Effekt auf die ausgelieferten Daten zu haben.

## Siehe auch
- [tonnenticker-spider](https://github.com/flohoff/tonnenticker-spider) von [Florian Lohoff](https://f.zz.de/) - Konvertiert Daten der Kreise Gütersloh und Warendorf in iCal-Dateien von der Abfall-App-REST-API. Im Kreis heißt die App Tonnenticker.
- [abfallapi_regioit_ha](https://github.com/tuxuser/abfallapi_regioit_ha) von [tuxuser](https://github.com/tuxuser/) - Integration verschiedener Abholstätten in Home Assistant, u.a. für die Stadt Gütersloh.