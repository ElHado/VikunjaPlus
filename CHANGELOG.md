# Changelog

Alle nennenswerten Änderungen an diesem Fork werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung an [Semantic Versioning](https://semver.org/lang/de/).

## [0.2.4] - 2026-08-18

### Geändert

- **Aufgaben-Dialog:** Neue Aufteilung in Tag-Auswahl + Uhrzeit-Auswahl
  (Keine, Heute, Morgen, 1 Woche, Nächsten Montag + 08:00, 12:00, 15:00, 18:00, 21:00)
- **Benutzerdefiniert** öffnet jetzt direkt Datum+Zeit-Picker (mit Vorlage)
- **Widget:** Lokalisierung via Android String-Resources (DE/EN)
- **Widget:** Aktualisiert sich jetzt beim App-Start

### Behoben

- **Kanban-Ansicht:** Neu erstellte Tasks erscheinen sofort im Bucket
- **Kanban-Ansicht:** Erledigte Tasks verschwinden sofort aus dem Bucket

## [0.2.3] - 2026-08-18

### Geändert

- **App-Name:** App heißt jetzt **Vikunja+** (Debug: *Vikunja+ (Dev)*).
- **Aufgeräumt:** Nicht mehr verwendete Konstanten entfernt (`repo`,
  `vStandardVerticalPadding`)
- **LICENSE:** Auf ElHado + 2026 aktualisiert

### Hinzugefügt

- **Einstellungen:** Server-URL wird über der Versionsnummer angezeigt
- **Einstellungen:** Fork-Hinweis ist jetzt klickbar (öffnet go-vikunja/app auf GitHub)
- **Einstellungen:** MIT License-Hinweis unter dem Fork-Link
- **Einstellungen:** App-Version wird über dem Abmelden-Button angezeigt

## [0.2.2] - 2026-08-17

### Behoben

- **HTML-Tags in Benachrichtigungen entfernt**
  Task-Beschreibungen werden von Vikunja als HTML gespeichert. Die Tags
  wurden nun sichtbar in Benachrichtigungen angezeigt. Ein HTML-Stripper
  bereinigt den Text vor der Anzeige.
- **Runtime-Absturz beim App-Start behoben**
  `AppLocalizations.of(context)` wurde in `initNotifications()` von
  `initState()` aus aufgerufen, bevor der Widget-Baum vollständig war.
  Jetzt wird der Default-Konstruktor von `NotificationHandler` genutzt.

### Entfernt

- **Sentry komplett entfernt** – Der hartkodierte DSN gehörte den
  Original-Entwicklern.
- **Versions-Check entfernt** – Kein GitHub-API-Call mehr gegen das
  Original-Repo.

### Geändert

- **Hintergrund-Aktualisierungsintervall:** Textfeld + Save-Button durch
  Schieberegler ersetzt. Default auf 30 Minuten (war 0 = aus).
- **Benachrichtigungen:** Titel ist jetzt der Task-Name, Text die
  Task-Beschreibung. Action-Button "Done" → "Erledigt", lokalisiert.
- **Aufgabensortierung:** Neue Option im Projekt-Bearbeiten-Dialog
  "Nach Fälligkeit sortieren" (umschaltbar).
- **Android-Tooling:** Kotlin von 2.2.20 auf 2.3.20 aktualisiert.

## [0.2.1] - 2026-08-16

### Behoben

- **HTML-Tags in Benachrichtigungen entfernt**
  Die Task-Beschreibung wird von Vikunja als HTML gespeichert (z. B.
  `<p>Text</p>`). In Benachrichtigungen wurden diese Tags nun sichtbar
  angezeigt. Ein HTML-Stripper bereinigt den Text vor der Anzeige.
- **Default Background-Refresh auf 30 Minuten** (war 0 = aus)
  Erinnerungen funktionieren jetzt out-of-the-box, ohne dass der User
  das Intervall erst in den Einstellungen setzen muss.

### Geändert

- **Background-Refresh-Einstellung:** Textfeld + Save-Button durch
  Schieberegler ersetzt. Stufen: Aus, 15/30/45 Min, 1–6 Stunden.
  Speichert automatisch beim Loslassen.
- **Notification-Titel und -Text:** Titel ist jetzt der Task-Name
  (statt "Due Reminder" / "Reminder"), Text ist die Task-Beschreibung
  (statt "The task 'X' is due" / "This is your reminder for 'X'").
- **Notification-Lokalisierung:** Action-Button "Done" → "Erledigt",
  Android-Channel-Namen auf Deutsch, alle Notification-Strings jetzt
  über ARB übersetzbar.
- **Aufgabensortierung in Projekten:** Neue Option im Projekt-Bearbeiten-
  Dialog "Nach Fälligkeit sortieren" – Aufgaben werden dann aufsteigend
  nach Fälligkeitsdatum sortiert (aktuellste zuerst). Standard ist die
  bisherige manuelle Sortierung.

## [0.2.0] - 2026-08-16

### Hinzugefügt

- **Deutsche Übersetzung komplettiert**
  Die App ist jetzt vollständig auf Deutsch nutzbar. Alle ~150 Textschlüssel
  wurden übersetzt (Menüs, Fehlermeldungen, Prioritäten, Einstellungen, etc.).
- **Eigenes App-Logo** – das Fork-Logo ersetzt das originale Vikunja-Logo.

### Behoben

- **Text-Overflow im Menü** – der deutsche Text "Nur Aufgaben mit
  Fälligkeitsdatum" war länger als der verfügbare Platz im Popup-Menü.
  Gekürzt und damit den gelb-schwarzen Overflow-Indikator entfernt.

## [0.1.9] - 2026-08-13

### Behoben

- **Benachrichtigungen bleiben nach App-Start erhalten**
  Bisher wurde bei jedem Hintergrund-Sync `cancelAll()` aufgerufen, wodurch
  alle Benachrichtigungen gelöscht wurden – auch die, die bereits in der
  Notification-Leiste angezeigt wurden. Jetzt werden nur noch die noch
  geplanten (pending) Benachrichtigungen ersetzt. Bereits angezeigte bleiben
  stehen, bis sie manuell bearbeitet oder entfernt werden.
- **Unbehandelte Netzwerk-Exceptions im HTTP-Client behoben**
  In `get/delete/post/put` wurde ein `Future` ohne `await` aus einem
  `try`-Block zurückgegeben. Dadurch wurden Exceptions (z. B. Timeouts)
  nicht vom `catch`-Block abgefangen und konnten unbehandelt durchschlagen.
  Der Rückgabewert wird jetzt awaited.
- **Dasselbe Muster in `HomePage.scheduleIntent()` behoben**
  Ein `return` eines `Future` in einer `void`-Methode ließ Fehler im
  `try`-Block ungefangen durchlaufen – jetzt mit `await` abgesichert.

### Geändert

- **Task-Reihenfolge: `onReorder` → `onReorderItem`**
  Der alte Callback ist in Flutter 3.41+ deprecated. Die manuelle
  Index-Korrektur (`newIndex -= 1`) wurde entfernt, da der neue Callback
  die Indizes bereits korrigiert liefert – eine doppelte Korrektur hätte
  Tasks an falsche Positionen verschoben.

### Sonstiges

- Experimentelle Sentry-Option `profilesSampleRate` entfernt (Analyzer-Warnung).
- `custom_lint`-Plugin aus der Analyzer-Konfiguration entfernt
  (inkompatibel mit Dart 3.13; Riverpod-Major-Upgrade später möglich).
- Unnötigen Cast in einem Test entfernt.
- **Codebasis ist nun analyzer-frei:** `dart analyze` meldet 0 Issues,
  alle 181 Tests laufen durch.

[0.1.9]: https://github.com/go-vikunja/app/compare/v0.1.8-beta...HEAD
