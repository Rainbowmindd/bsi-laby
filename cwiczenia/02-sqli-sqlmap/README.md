# Ćwiczenie 2. SQL injection i sqlmap

Celowo podatna aplikacja sklepu internetowego „Przecena” i instrukcja do ćwiczenia z wstrzyknięć
SQL. Instrukcja prowadzi od ręcznego wykrycia podatności (obejście logowania, UNION, odczyt
`information_schema`) do automatycznego odczytu całej bazy narzędziem sqlmap, dla parametru GET
i pola formularza POST. Na końcu ten sam atak zostaje powtórzony na wersji poprawionej z zapytaniem
parametryzowanym.

Instrukcja: [instrukcja.pdf](instrukcja.pdf)

## Zawartość katalogu

- `instrukcja.pdf` – instrukcja do ćwiczenia,
- `app.mjs` – aplikacja testowana w ćwiczeniu,
- `package.json` – zależności i polecenie uruchamiające,
- `request1.txt` – zapisane żądanie logowania, używane przez sqlmap w części z metodą POST,
- `zrodla/` – źródło instrukcji w formacie Typst wraz ze zrzutami ekranu.

## Uruchomienie aplikacji

Wymagany jest Node.js w wersji 18 lub nowszej.

```bash
npm install
npm start
```

Aplikacja nasłuchuje pod adresem `http://127.0.0.1:8000`. Baza danych (PostgreSQL przez bibliotekę
PGlite) działa w pamięci, więc ponowne uruchomienie aplikacji przywraca stan początkowy.

## sqlmap

Część automatyczna wymaga narzędzia sqlmap i Pythona. sqlmap pobiera się poleceniem:

```bash
git clone https://github.com/sqlmapproject/sqlmap.git
```

a uruchamia z jego katalogu poleceniem `python sqlmap.py`. Szczegóły są w instrukcji.

## Zasady

Aplikacja zawiera podatności celowo i służy wyłącznie do nauki. Należy ją uruchamiać tylko na
własnym komputerze. Opisane techniki wolno stosować wyłącznie wobec własnych systemów lub za
pisemną zgodą właściciela systemu.
