# Changelog

Alle nennenswerten Änderungen an diesem Fork werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.1.0/),
die Versionierung an [Semantic Versioning](https://semver.org/lang/de/).

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
