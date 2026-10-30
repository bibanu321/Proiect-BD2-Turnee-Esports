# Proiect Baze de Date Avansate - Platformă de Turnee Esports (CS2)

## Etapa 0: Tema și Domeniul Aplicației
Proiectul constă într-o platformă web destinată organizării și gestionării turneelor de Esports (Counter-Strike 2). Aplicația permite administrarea jucătorilor și a cotelor lor valorice (ELO), formarea echipelor și desemnarea căpitanilor, înscrierea echipelor în competiții și gestionarea rezultatelor meciurilor.

---

## Etapa 1: Modelarea Bazei de Date (6 Tabele, Relații și Fixtures)
Schema relațională conține **6 tabele** normalizate, depășind pragul minim de 5 tabele:
1. **`Jucatori`**: Stochează profilul individual al jucătorilor (`id_jucator`, `nickname`, `email`, `rank_elo`, `tara`, `data_inregistrare`).
2. **`Echipe`**: Stochează datele echipelor (`id_echipa`, `nume_echipa`, `tag`, `id_capitan`, `data_creare`). Are relație **1:N** cu `Jucatori` prin cheia străină `id_capitan`.
3. **`Membri_Echipa`**: Tabelă asociativă care rezolvă relația **M:N** dintre `Echipe` și `Jucatori`, păstrând rolul din joc (`IGL`, `AWPer`, `Entry Fragger`, `Support`, `Lurker`).
4. **`Turnee`**: Stochează competițiile organizate (`id_turneu`, `titlu`, `joc`, `max_echipe`, `fond_premiere`, `status`).
5. **`Inscrieri_Turneu`**: Tabelă asociativă care rezolvă relația **M:N** dintre `Turnee` și `Echipe`, păstrând numărul de cap de serie (`seed_nr`).
6. **`Meciuri`**: Stochează partidele disputate în cadrul unui turneu (`id_meci`, `id_turneu`, `id_echipa1`, `id_echipa2`, `runda`, `scor_echipa1`, `scor_echipa2`, `id_castigator`, `status_meci`).

* **Diagrama Entitate-Relație (ERD):** Se regăsește în fișierul `diagrama_erd.png`.
* **Fixtures (Date de test):** Scriptul `baza_de_date.sql` conține structura DDL și inserarea datelor inițiale de test pentru toate cele 6 tabele.

---

## Etapa 2: Operații CRUD și Descrierea Paginilor
Interfața aplicației (`index.html`) implementează operațiile **CRUD (Create, Read, Update, Delete)** împărțite pe următoarele secțiuni funcționale:
1. **Secțiunea Gestiune Echipe:**
   * **Create:** Formular pentru adăugarea unei echipe noi împreună cu căpitanul acesteia.
   * **Read:** Tabel dinamic cu afișarea echipelor, a tag-ului, a căpitanului și a mediei ELO calculate.
   * **Update:** Modificarea numelui unei echipe existente.
   * **Delete:** Ștergerea unei echipe (cu propagare în cascadă asupra meciurilor asociate).
2. **Secțiunea Gestiune Meciuri și Scoruri:**
   * **Create:** Formular pentru programarea unui meci nou între două echipe diferite (cu validare `CHECK` împotriva alegerii aceleiași echipe).
   * **Read:** Listarea meciurilor programate și finalizate, alături de rundă și scor.
   * **Update:** Actualizarea scorului unui meci și schimbarea automată a statusului în *Finalizat*.
   * **Delete:** Anularea/ștergerea unui meci din baza de date.
3. **Secțiunea Jucători & Jurnal SQL:**
   * **Read & Delete:** Vizualizarea lotului de jucători și eliminarea înregistrărilor, alături de o consolă care afișează în timp real comenzile SQL corespunzătoare fiecărei acțiuni CRUD.
