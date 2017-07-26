# proHomeeStatus
Raspberry Pi Bash Script für An und Abwesenheitserkennung per Bluetooth und Gigaset G-tags

Installation:

Installation als Cronjob, jede Minute wird geprüft ob das Script schon läuft, wenn nicht wird es gestartet
Vorher bitte im Script die G-Tags Adressen und Homee Konfiguration vornehmen
Console: crontab -e
*/1 * * * * cd /home/pi && ./scanner.sh

