# Müllabfuhr-REST-API für die Stadt Gütersloh

## Intro

*Als Bewohnender der Stadt Gütersloh möchte ich die nächsten Termine zur Müllabfuhr in meiner Hausautomatisierung automatisiert abfragen können.*

Die Stadt Gütersloh versucht sich ja seit länger Zeit als "Smart City" - und oft genug besteht Digitalisierung nur aus einer App oder iCal-Dateien, die die alten PDF-Dateien (aus der Digitalisierung 1.0) als elektronisches Format ersetzt haben.

![Das Internet ist für uns alle Neuland!](assets/neuland.gif)

Ich finde beides nicht sehr befriedigend, denn beide Quellen sind wirklich nur die elektronische Repräsentation der alten Drucke. D.h. insbesondere, dass z.B. eine Anfrage wie "Gibt es diese Woche eine Abholung?" nicht ad hoc beantwortet werden kann, da beide Quellen immer **alle** verfügbaren Termine inkl. die der Vergangenheit für das laufende Jahr (und ggf. noch für das vergangene bzw. kommende Jahr) beinhalten.

Es stellt sich außerdem die Frage, inwiefern es nötig ist, dass die Daten an ein privates Unternehmen anstatt von der Kommune direkt an die Bürger geliefert werden, die die Erstellung dieser Daten mit ihren Abgaben, Gebühren und Steuern finanziert haben.

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

Um meinen Bedarf an einer API zu befriedigen, habe ich als Fingerübung selbst eine geschrieben. Die Daten werden aus den iCal-Dateien bezogen (da ich die API der App zum Zeitpunkt meiner Umsetzung noch nicht kannte), mit Perl extrahiert und in einer MariaDB-Instanz gespeichert. 

Die Daten werden einmal monatlich aktualisiert, immer zum Ersten des Monats.

Bis dato erfüllt sie die Anforderungen 1 - 4w.ii vollständig.

## Quellen
## REST-API der Abfall-App

Die REST-API der RegioIT (mit mitmproxy aus der iOS-App abgeschnorchelt) liefert im Prinzip all die Daten, die auch in den iCal-Dateien vorhanden sind.

### Endpunkte

#### Unterstütze Orte: 
- [/orte](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/orte/)
- In Gütersloh uninteressant, da die App nur die Termine für Gütersloh enthält. Gütersloh hat die ID ``445739``.

#### Verzeichnis der Straßen im Ort
- [/orte/445739/strassen](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/orte/445739/strassen)
- Liefert eine Liste aller Straßen in Gütersloh (in CAPS und abgekürzt ``(>ლ)``) mit ihrer ID zurück, der ~~Tulpenweg~~TULPENWEG hat z.B. die ID ``446868``.

#### Metadaten einer Straße 
- [/strassen/446868](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/strassen/446868/)
- Enthält der Namen der Straße, erneut in CAPS und abgekürzt, und den Ort. Der Zugriff auf Straßen-ID außerhalb des geographischen Bereichs der App, z.B. Stadt Gütersloh, ist nicht möglich. Es scheint aber, dass die ID bundesweit eindeutig ist, da im Kreis Gütersloh / Warendorf die ID, die in der Stadt Gütersloh vergeben sind, nicht erneut vorkommen. Das lässt 

#### Fraktionen (einer Straße)
- [/fraktionen](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/fraktionen)
- [/strassen/446868/fraktionen](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/strassen/446868/fraktionen)
- "Fraktionen" scheinen im internen Sprachgebrauch die Müllart zu sein, die abgeholt werden. So steht die Fraktion 3 für Altpapier. Dieser Endpunkt liefert alle Fraktionen  (für eine spezifische Straße) zurück, inkl. einer Icon-ID und ein RGB-Farbcode für die Darstellung in der App.

### Termine einer Straße
- [/strassen/446868/termine](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/strassen/446868/termine)
- Liefert sämtliche Abholungstermine einer Straße für jede Fraktion kombiniert in einem Endpunkt.

### Appdata
- [/appdata](https://gt2-abfallapp.regioit.de/abfall-app-gt2/rest/appdata)
- Liefert Meta-Informationen über den Datenbestand. Welche Uhrzeit 25:00 sein soll, hätte ich doch gerne erklärt ``(>ლ)``.

### Login zur Datenpflege
- [/login.jsf](https://gt2-abfallapp.regioit.de/abfall-app-gt2/login.jsf)
- Bingo.

### Known unknows
- Es muss irgendwo noch einen (oder mehrere) Endpunkt geben, der Aktuelles, Standorte von Altkleider- und Altglascontainern, Ratgeber und das Impressum zurückliefert.

## iCal-Dateien

RegioIT bietet außerdem die Möglichkeit [iCal-Dateien](https://abfallkalender.regioit.de/kalender-gt/) (und PDF) zu beziehen. Die Jahresauswahl scheint zu diesem Zeitpunkt (Anfang Dezember 2020) keinen nennenswerten Effekt auf die ausgelieferten Daten zu haben.

## Siehe auch
- [tonnenticker-spider](https://github.com/flohoff/tonnenticker-spider) von [Florian Lohoff](https://f.zz.de/) - Konvertiert Daten der Kreise Gütersloh und Warendorf in iCal-Dateien von der Abfall-App-REST-API. Im Kreis heißt die App Tonnenticker.