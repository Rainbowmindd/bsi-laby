// Sklep "Przecena" - BSI, cwiczenia z SQL injection i sqlmap
// uruchomienie: npm install, potem npm start
// baza dziala w pamieci (PGlite), po restarcie wraca do stanu poczatkowego
import express from "express";
import { PGlite } from "@electric-sql/pglite";
import crypto from "node:crypto";

const db = new PGlite(); // baza w pamieci, znika po zatrzymaniu aplikacji
const app = express();
app.use(express.urlencoded({ extended: false }));

// haslo w bazie trzymamy jako skrot MD5, tak jak wiele aplikacji
const md5 = (s) => crypto.createHash("md5").update(s).digest("hex");

// dane poczatkowe
await db.exec(`
  CREATE TABLE users (
    id serial PRIMARY KEY,
    username text,
    password text,
    role text
  );
  INSERT INTO users (username, password, role) VALUES
    ('alice', '${md5("sunshine")}', 'user'),
    ('bob',   '${md5("football")}', 'user'),
    ('admin', '${md5("letmein")}',  'admin');

  CREATE TABLE products (
    id serial PRIMARY KEY,
    name text,
    description text,
    price integer
  );
  INSERT INTO products (name, description, price) VALUES
    ('Klawiatura', 'mechaniczna, podswietlana', 199),
    ('Mysz', 'bezprzewodowa', 89),
    ('Monitor', '27 cali, 144 Hz', 1299),
    ('Laptop', '14 cali, 16 GB RAM', 3499);
`);

// pomocnicze

function page(title, body) {
  return `<!doctype html><html lang="pl"><meta charset="utf-8">
<title>${title}</title><body style="font-family:sans-serif;max-width:680px;margin:2rem auto">
<h1>Sklep „Przecena”</h1>${body}</body></html>`;
}

function esc(s) {
  // tylko do bezpiecznego wyswietlania tekstu w HTML, nie ma wplywu na zapytania SQL
  return String(s).replace(/[&<>"]/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c])
  );
}

function currentUser(cookie) {
  // ciasteczko sesji to sam login (jak w cwiczeniu 1), bez podpisu
  const m = /(?:^|;\s*)session=([^;]+)/.exec(cookie || "");
  return m ? decodeURIComponent(m[1]) : null;
}

// strona glowna

app.get("/", (req, res) => {
  const who = currentUser(req.headers.cookie);
  const status = who
    ? `<p>Zalogowany jako <b>${esc(who)}</b>. <a href="/logout">Wyloguj</a></p>`
    : `<p>Nie jesteś zalogowany.</p>`;
  res.send(
    page(
      "Sklep",
      `${status}
<h2>Logowanie</h2>
<form method="post" action="/login">
  <p>Login: <input name="username"></p>
  <p>Hasło: <input name="password" type="password"></p>
  <button>Zaloguj</button>
</form>

<h2>Wyszukiwarka produktów</h2>
<form method="get" action="/search">
  <p>Nazwa: <input name="name" value="Monitor"></p>
  <button>Szukaj</button>
</form>`
    )
  );
});

// logowanie - PODATNE: login i haslo sklejane w zapytanie SQL
// obejscie: w polu login wpisz   ' OR '1'='1' --
app.post("/login", async (req, res) => {
  const { username, password } = req.body;
  const sql =
    "SELECT username, role FROM users WHERE username = '" +
    username +
    "' AND password = '" +
    md5(password) +
    "'";
  try {
    const r = await db.query(sql);
    if (r.rows.length === 0) {
      return res.send(page("Błąd", "<p>Złe dane logowania. <a href='/'>Wróć</a></p>"));
    }
    const u = r.rows[0];
    res.setHeader("Set-Cookie", `session=${encodeURIComponent(u.username)}; Path=/`);
    res.send(
      page(
        "Panel",
        `<p>Zalogowano jako <b>${esc(u.username)}</b> (rola: ${esc(u.role)}).</p>
<p><a href="/">Strona główna</a></p>`
      )
    );
  } catch (e) {
    // tryb debugowania: tresc bledu bazy trafia do odpowiedzi (error-based)
    res.status(500).send(page("Błąd SQL", `<pre>${esc(e.message)}</pre>`));
  }
});

app.get("/logout", (req, res) => {
  res.setHeader("Set-Cookie", "session=; Path=/; Max-Age=0");
  res.redirect("/");
});

// wyszukiwarka - PODATNA: nazwa sklejana w zapytanie SQL
// to jest glowny cel dla sqlmap (parametr GET "name")
app.get("/search", async (req, res) => {
  const name = req.query.name ?? "";
  const sql =
    "SELECT name, description FROM products WHERE name = '" + name + "'";
  try {
    const r = await db.query(sql);
    const rows = r.rows
      .map((p) => `<li>${esc(p.name)} — ${esc(p.description)}</li>`)
      .join("");
    res.send(
      page(
        "Wyniki",
        `<p>Zapytanie o nazwę: <code>${esc(name)}</code></p>
<ul>${rows || "<li>Brak wyników</li>"}</ul>
<p><a href="/">Wróć</a></p>`
      )
    );
  } catch (e) {
    // tryb debugowania: tresc bledu bazy trafia do odpowiedzi (error-based)
    res.status(500).send(page("Błąd SQL", `<pre>${esc(e.message)}</pre>`));
  }
});

// wersja poprawiona - zapytanie parametryzowane (slajd 38)
// te same wejscia co /search, ale wartosc idzie osobnym kanalem
app.get("/fixed/search", async (req, res) => {
  const name = req.query.name ?? "";
  try {
    const r = await db.query(
      "SELECT name, description FROM products WHERE name = $1",
      [name]
    );
    const rows = r.rows
      .map((p) => `<li>${esc(p.name)} — ${esc(p.description)}</li>`)
      .join("");
    res.send(
      page(
        "Wyniki (wersja poprawiona)",
        `<p>Zapytanie o nazwę: <code>${esc(name)}</code></p>
<ul>${rows || "<li>Brak wyników</li>"}</ul>
<p><a href="/">Wróć</a></p>`
      )
    );
  } catch (e) {
    res.status(500).send(page("Błąd SQL", `<pre>${esc(e.message)}</pre>`));
  }
});

app.listen(8000, "127.0.0.1", () => {
  console.log("Aplikacja nasluchuje pod http://127.0.0.1:8000");
});
