# MyConfigFiles

Aktualny snapshot: **2026-11-18**, CachyOS / KDE Plasma / Wayland.

- `current/` — aktualne ustawienia komputera Ben, struktura względem katalogu domowego.
- `old/` — poprzednia konfiguracja Arch/bspwm przeniesiona z głównego katalogu repo. Archiwum, nie instalować razem z aktualną konfiguracją.
- `current/packages-reference.txt` — lista zainstalowanych pakietów jako punkt odniesienia, nie lista do automatycznej instalacji na laptopie.

## Co jest w snapshotcie

Panel KDE z pięcioma pulpitami, Panel Colorizer, własny przełącznik pulpitów i style czujników CPU/GPU oraz sieci, ustawienia KWin, skróty, powiadomienia, kolorystyka, lokalne widżety, Alacritty i konfiguracja fish. Licencje i informacje o autorach dołączonych widżetów zachowano w ich katalogach.

Nie eksportujemy haseł, tokenów, profili przeglądarek, historii terminala, rozmów Codexa/Signala ani danych kont. Historia Git i `old/` zawierają dotychczasowe pliki repo; nie są częścią nowego eksportu.

## Instrukcja dla Codexa na laptopie

1. Obejrzyj `current/` i lokalny system. Ustal dystrybucję, wersję Plasma, rozdzielczość i skalowanie monitorów, GPU oraz dostępne sensory.
2. Zrób kopię lokalnych ustawień przed zmianami. Nie nadpisuj całego `~/.config`.
3. Przenieś wybrane pliki z `current/.config/` i zasoby z `current/.local/share/` do odpowiednich katalogów użytkownika. Zachowaj istniejące dane aplikacji.
4. Ścieżki `/home/ben` w snapshotcie wskazują komputer źródłowy: dopasuj je do użytkownika laptopa. Sprawdź wszystkie odwołania do `/usr/share` i plików tapet; tapety i systemowe motywy nie muszą być dostępne na laptopie.
5. Panel pochodzi z konfiguracji wielomonitorowej. Dopasuj `lastScreen`, mapowanie ekranów i identyfikatory containmentów; najlepiej odtwarzać panel przez API skryptowe Plasma. Nie kopiuj konfiguracji monitorów ani układu okien na ślepo.
6. Czujniki komputera źródłowego: `cpu/all/usage`, `cpu/all/averageTemperature`, `gpu/gpu0/usage`, `gpu/gpu0/temperature`, `network/all/download`, `network/all/upload`. Odkryj sensory laptopa przez ksystemstats. Nie zakładaj, że `gpu0` oznacza właściwe GPU ani że nazwy temperatur będą identyczne.
7. Fish źródłuje `/usr/share/cachyos-fish-config/cachyos-config.fish`. Na innej dystrybucji zapewnij ten pakiet albo warunkowo zastąp tę linię. Prompt i kolory częściowo pochodzą z systemowego pakietu CachyOS. Dodatkowa ścieżka LM Studio jest opcjonalna.
8. Alacritty wymaga `JetBrainsMono Nerd Font Mono`; KDE używa m.in. Inter i SFNS Display. Zainstaluj dostępne fonty lub dobierz zamienniki. Sprawdź nazwy motywów w `kdeglobals`, `plasmarc` i ustawieniach GTK/Kvantum.
9. Panel Colorizer może wymagać aktualizacji dla innej wersji Plasma. Zawarty snapshot nie zawiera skompilowanego pluginu C++ ani obietnicy zgodności na innym systemie.
10. Po wdrożeniu sprawdź: wszystkie 5 pulpitów, menu Start, uruchamianie aplikacji, zasobnik, zegar, odczyty i temperatury, odświeżanie co 5 sekund oraz brak ucinania tekstu. Restartuj samą powłokę Plasma lub wyloguj się dopiero po zapisaniu pracy.

Snapshot został sprawdzony statycznie; nie był wdrażany ani testowany na starym laptopie.

## Weather widget

Bundled OpenWeather / WeatherAPI keys have been removed from the exported widget source. Supply your own provider key locally if required; never commit it.
