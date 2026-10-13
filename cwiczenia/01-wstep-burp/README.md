# Ćwiczenie 1. Pierwsze kroki z Burp Suite

Celowo podatna aplikacja sklepu internetowego „Przecena” i instrukcja do pierwszych ćwiczeń
z Burp Suite. Instrukcja prowadzi od konfiguracji proxy do wykrycia ośmiu podatności i opisania
ich w formie raportu z testu penetracyjnego.

Instrukcja: [instrukcja.pdf](instrukcja.pdf)

## Zawartość katalogu

- `instrukcja.pdf` – instrukcja do ćwiczenia,
- `app.py` – aplikacja testowana w ćwiczeniu,
- `zrodla/` – źródło instrukcji w formacie Typst i zrzuty ekranu.

## Uruchomienie aplikacji

Wymagany jest Python 3.12 lub nowszy.

```bash
python -m pip install fastapi uvicorn python-multipart
python -m uvicorn app:app --port 8000
```

Aplikacja nasłuchuje pod adresem `http://127.0.0.1:8000`. Dane są przechowywane w pamięci, więc
ponowne uruchomienie aplikacji przywraca stan początkowy.

## Zasady

Aplikacja zawiera podatności celowo i służy wyłącznie do nauki. Należy ją uruchamiać tylko na
własnym komputerze. Opisane techniki wolno stosować wyłącznie wobec własnych systemów lub za
pisemną zgodą właściciela systemu.
