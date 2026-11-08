# Proiect Baze de Date Avansate - Platformă de Turnee Esports (CS2)

## Etapa 0: Tema și Domeniul Aplicației
Proiectul constă într-o platformă web destinată organizării și gestionării turneelor de Esports (Counter-Strike 2). Aplicația permite administrarea jucătorilor și a cotelor lor valorice (ELO), formarea echipelor și desemnarea căpitanilor, înscrierea echipelor în competiții, gestionarea rezultatelor meciurilor, controlul accesului pe bază de roluri și optimizarea performanței la volume mari de date.

---

## Etapa 1: Modelarea Bazei de Date (7 Tabele, Relații și Fixtures)
Schema relațională conține **7 tabele** normalizate (depășind cerința minimă de 6 tabele):
1. **`Jucatori`**: Stochează profilul individual al jucătorilor (`id_jucator`, `nickname`, `email`, `rank_elo`, `tara`, `data_inregistrare`).
2. **`Echipe`**: Stochează datele echipelor (`id_echipa`, `nume_echipa`, `tag`, `id_capitan`, `data_creare`). Relație **1:N** cu `Jucatori` prin `id_capitan`.
3. **`Membri_Echipa`**: Tabelă asociativă (**M:N** între `Echipe` și `Jucatori`), păstrând rolul din joc (`IGL`, `AWPer`, `Entry Fragger`, `Support`, `Lurker`).
4. **`Turnee`**: Stochează competițiile organizate (`id_turneu`, `titlu`, `joc`, `max_echipe`, `fond_premiere`, `status`).
5. **`Inscrieri_Turneu`**: Tabelă asociativă (**M:N** între `Turnee` și `Echipe`), păstrând numărul de cap de serie (`seed_nr`).
6. **`Meciuri`**: Stochează partidele disputate (`id_meci`, `id_turneu`, `id_echipa1`, `id_echipa2`, `runda`, `scor_echipa1`, `scor_echipa2`, `id_castigator`, `status_meci`).
7. **`Utilizatori`**: Stochează conturile de acces în platformă (`id_utilizator`, `username`, `parola_hash`, `rol`, `id_jucator_asociat`, `ultimul_login`).

* **Diagrama Entitate-Relație (ERD):** Se regăsește în fișierul `diagrama_erd.png`.
* **Fixtures (Date de test):** Scriptul `baza_de_date.sql` conține structura DDL și inserarea datelor inițiale pentru toate tabelele.

---

## Etapa 2: Operații CRUD și Descrierea Paginilor
Interfața aplicației (`index.html`) implementează operațiile **CRUD (Create, Read, Update, Delete)** împărțite pe următoarele secțiuni:
1. **Secțiunea Gestiune Echipe:** Create (adăugare echipă și căpitan), Read (afișare tabel și calcul ELO mediu), Update (redenumire echipă), Delete (ștergere cu propagare în cascadă).
2. **Secțiunea Gestiune Meciuri și Scoruri:** Create (programare meci nou cu validare `CHECK`), Read (listare meciuri), Update (actualizare scor și status), Delete (anulare meci).
3. **Secțiunea Jucători & Jurnal SQL:** Read, filtrare rapidă și Delete asupra înregistrărilor din `Jucatori`, însoțite de consola live de interogări SQL.

---

## Etapa 3: Autentificare și Controlul Accesului (Minimum 3 Roluri)
Aplicația implementează autentificarea utilizatorilor prin tabelul `Utilizatori` (cu parole stocate sub formă de hash SHA-256) și controlul accesului bazat pe **3 roluri distincte (RBAC)**:
1. **`ADMIN` (`admin_cosmin`)**: Drepturi complete (`CREATE`, `READ`, `UPDATE`, `DELETE`) asupra tuturor entităților (echipe, meciuri, jucători) și acces la administrarea indecșilor / Load Testing.
2. **`ORGANIZATOR` (`org_faceit`)**: Drepturi de creare și actualizare a meciurilor și scorurilor oficiale (`CREATE` / `UPDATE` pe `Meciuri`), dar **fără drept de ștergere (`DELETE`)** sau de modificare a echipelor.
3. **`JUCATOR` / Căpitan (`capitan_s1mple`)**: Drepturi de vizualizare (`READ`) și de înscriere/actualizare a propriei echipe (`CREATE` / `UPDATE` pe `Echipe`), având **restricționată modificarea scorurilor oficiale și ștergerea datelor**.

---

## Etapa 4: Performanță — Indecși și Load Test
Pentru optimizarea timpilor de răspuns pe volume mari de date, au fost proiectați **4 indecși B-Tree** în `baza_de_date.sql`:
1. **`idx_jucatori_elo_tara` ON `Jucatori(rank_elo DESC, tara)`**: Index compus care elimină operația costisitoare de `FULL TABLE SCAN` și sortare la filtrarea liderilor ELO pe țări, transformând execuția în `INDEX RANGE SCAN`.
2. **`idx_meciuri_turneu_status` ON `Meciuri(id_turneu, status_meci)`**: Optimizează extragerea meciurilor programate sau finalizate din cadrul unui turneu activ.
3. **`idx_membri_jucator` ON `Membri_Echipa(id_jucator)`**: Optimizează operațiile de `JOIN` la calculul mediei ELO pe echipe.
4. **`idx_utilizatori_rol` ON `Utilizatori(rol)`**: Optimizează verificarea permisiunilor la autentificare.

### Rezultate Load Test (10.000 de înregistrări generate prin `proc_load_test_jucatori`):
* **Interogare testată:** `SELECT * FROM Jucatori WHERE tara = 'Romania' AND rank_elo >= 2200 ORDER BY rank_elo DESC;`
* **Timp de execuție FĂRĂ Index (`FULL TABLE SCAN`):** ~14.5 ms – 22.0 ms (parcurgere secvențială $O(N)$ a celor 10.000 de rânduri).
* **Timp de execuție CU Index (`INDEX RANGE SCAN` pe `idx_jucatori_elo_tara`):** ~0.5 ms – 1.2 ms (căutare în arbore B-Tree $O(\log N)$).
* **Factor de accelerare:** Îmbunătățire a timpului de răspuns de aproximativ **15x – 25x**.
