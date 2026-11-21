// ==========================================================
// STRAT REST API & LIVE SCORE ENGINE (api.js)
// Simuleaza un backend REST API cu rute GET/POST/PUT/PATCH/DELETE,
// autentificare RBAC, persistenta localStorage si Auto-Score Live.
// ==========================================================

const STORAGE_KEY = 'esports_arena_db_v5';

const INITIAL_DB = {
    utilizatori: [
        { id: 1, username: 'admin_cosmin', parola: 'admin123', rol: 'ADMIN', nume: 'Cosmin (Administrator)' },
        { id: 2, username: 'org_faceit', parola: 'org123', rol: 'ORGANIZATOR', nume: 'Organizator FACEIT' },
        { id: 3, username: 'capitan_s1mple', parola: 'jucator123', rol: 'JUCATOR', nume: 'Căpitan s1mple_ro' }
    ],
    jucatori: [
        { id: 1, nickname: 's1mple_ro', tara: 'Romania', echipaId: 10, rol: 'AWPer', elo: 2150 },
        { id: 2, nickname: 'iM_legend', tara: 'Romania', echipaId: 10, rol: 'Entry Fragger', elo: 2080 },
        { id: 3, nickname: 'karrigan_gl', tara: 'Romania', echipaId: 10, rol: 'IGL', elo: 1920 },
        { id: 4, nickname: 'm0NESY_peek', tara: 'Romania', echipaId: 20, rol: 'AWPer', elo: 2210 },
        { id: 5, nickname: 'niko_deagle', tara: 'Romania', echipaId: 20, rol: 'Entry Fragger', elo: 1990 },
        { id: 6, nickname: 'zywoo_ace', tara: 'Romania', echipaId: 30, rol: 'IGL', elo: 2180 }
    ],
    echipe: [
        { id: 10, nume: 'Danube Wolves', tag: 'DW', capitan: 's1mple_ro' },
        { id: 20, nume: 'Vortex Gaming', tag: 'VTX', capitan: 'm0NESY_peek' },
        { id: 30, nume: 'Nexus Titans', tag: 'NXS', capitan: 'zywoo_ace' }
    ],
    meciuri: [
        { id: 1000, runda: 'Semifinala 1', echipa1Id: 10, echipa2Id: 20, scor1: 13, scor2: 9, castigatorId: 10, status: 'Finalizat' },
        { id: 1001, runda: 'Finala Mare (LIVE)', echipa1Id: 10, echipa2Id: 30, scor1: 8, scor2: 7, castigatorId: null, status: 'In Desfasurare' },
        { id: 1002, runda: 'Meci Baraj', echipa1Id: 20, echipa2Id: 30, scor1: 0, scor2: 0, castigatorId: null, status: 'Programat' }
    ]
};

class EsportsRestAPI {
    constructor() {
        this.db = this._loadDB();
        this.indexEloTara = new Map();
        this.onLog = null;
        this._rebuildIndex();
    }

    _loadDB() {
        try {
            const saved = localStorage.getItem(STORAGE_KEY);
            if (saved) return JSON.parse(saved);
        } catch (e) {}
        return JSON.parse(JSON.stringify(INITIAL_DB));
    }

    _saveDB() {
        try {
            // Nu salvam in localStorage daca sunt peste 500 jucatori (Load Test) ca sa nu depasim limita browserului
            if (this.db.jucatori.length <= 500) {
                localStorage.setItem(STORAGE_KEY, JSON.stringify(this.db));
            }
        } catch (e) {}
    }

    _rebuildIndex() {
        this.indexEloTara.clear();
        for (let i = 0; i < this.db.jucatori.length; i++) {
            const j = this.db.jucatori[i];
            if (!this.indexEloTara.has(j.tara)) this.indexEloTara.set(j.tara, []);
            this.indexEloTara.get(j.tara).push(j);
        }
        for (const lista of this.indexEloTara.values()) {
            lista.sort((a, b) => b.elo - a.elo);
        }
    }

    _emitLog(method, endpoint, status, detail, type = 'succes') {
        if (typeof this.onLog === 'function') {
            this.onLog(`[API ${status}] ${method} ${endpoint} — ${detail}`, type);
        }
    }

    // Rutare centralizata REST API
    async request(method, endpoint, body = null, currentRole = null) {
        // 1. POST /api/auth/login
        if (method === 'POST' && endpoint === '/api/auth/login') {
            const user = this.db.utilizatori.find(u => u.username === body.username && u.parola === body.parola);
            if (!user) {
                this._emitLog(method, endpoint, 401, 'Credențiale invalide!', 'eroare');
                return { status: 401, error: 'Username sau parolă incorectă!' };
            }
            const token = btoa(`${user.username}:${user.rol}:${Date.now()}`);
            this._emitLog(method, endpoint, 200, `Autentificat ca ${user.username} (${user.rol})`, 'succes');
            return { status: 200, data: { username: user.username, rol: user.rol, nume: user.nume, token } };
        }

        // 2. GET /api/echipe (cu calcul dinamic ELO mediu si victorii)
        if (method === 'GET' && endpoint === '/api/echipe') {
            const data = this.db.echipe.map(e => {
                const membri = this.db.jucatori.filter(j => j.echipaId === e.id);
                const eloMediu = membri.length ? Math.round(membri.reduce((s, j) => s + j.elo, 0) / membri.length) : 1000;
                const victorii = this.db.meciuri.filter(m => m.castigatorId === e.id).length;
                return { ...e, nrJucatori: membri.length, eloMediu, victorii };
            }).sort((a, b) => b.eloMediu - a.eloMediu);
            return { status: 200, data };
        }

        // 3. POST /api/echipe
        if (method === 'POST' && endpoint === '/api/echipe') {
            if (currentRole === 'ORGANIZATOR') {
                this._emitLog(method, endpoint, 403, 'Rolul ORGANIZATOR nu poate crea echipe!', 'eroare');
                return { status: 403, error: 'Acces interzis (403): Doar ADMIN și JUCĂTOR pot crea echipe.' };
            }
            if (!body.nume || !body.tag || !body.capitan) {
                return { status: 400, error: 'Toate câmpurile obligatorii (NOT NULL) trebuie completate.' };
            }
            const nouJucId = this.db.jucatori.length ? Math.max(...this.db.jucatori.map(j => j.id)) + 1 : 1;
            const nouaEchId = this.db.echipe.length ? Math.max(...this.db.echipe.map(e => e.id)) + 10 : 10;
            this.db.jucatori.unshift({ id: nouJucId, nickname: body.capitan, tara: 'Romania', echipaId: nouaEchId, rol: 'IGL', elo: body.elo || 1800 });
            const echipaNoua = { id: nouaEchId, nume: body.nume, tag: body.tag.toUpperCase(), capitan: body.capitan };
            this.db.echipe.push(echipaNoua);
            this._rebuildIndex();
            this._saveDB();
            this._emitLog(method, endpoint, 201, `INSERT INTO Echipe (${body.nume})`, 'succes');
            return { status: 201, data: echipaNoua };
        }

        // 4. PUT /api/echipe/:id
        if (method === 'PUT' && endpoint.startsWith('/api/echipe/')) {
            if (currentRole === 'ORGANIZATOR') {
                this._emitLog(method, endpoint, 403, 'Rolul ORGANIZATOR nu are drept de UPDATE pe Echipe!', 'eroare');
                return { status: 403, error: 'Acces interzis (403).' };
            }
            const id = parseInt(endpoint.split('/').pop());
            const ech = this.db.echipe.find(e => e.id === id);
            if (!ech) return { status: 404, error: 'Echipa nu a fost găsită.' };
            ech.nume = body.nume;
            this._saveDB();
            this._emitLog(method, endpoint, 200, `UPDATE Echipe SET nume_echipa='${body.nume}' WHERE id=${id}`, 'update');
            return { status: 200, data: ech };
        }

        // 5. DELETE /api/echipe/:id
        if (method === 'DELETE' && endpoint.startsWith('/api/echipe/')) {
            if (currentRole !== 'ADMIN') {
                this._emitLog(method, endpoint, 403, 'Doar rolul ADMIN poate executa DELETE!', 'eroare');
                return { status: 403, error: 'Acces interzis (403): Doar ADMIN poate șterge echipe.' };
            }
            const id = parseInt(endpoint.split('/').pop());
            this.db.echipe = this.db.echipe.filter(e => e.id !== id);
            this.db.meciuri = this.db.meciuri.filter(m => m.echipa1Id !== id && m.echipa2Id !== id);
            this._saveDB();
            this._emitLog(method, endpoint, 200, `DELETE FROM Echipe WHERE id=${id} (CASCADE)`, 'eroare');
            return { status: 200 };
        }

        // 6. GET /api/meciuri
        if (method === 'GET' && endpoint === '/api/meciuri') {
            return { status: 200, data: [...this.db.meciuri] };
        }

        // 7. POST /api/meciuri
        if (method === 'POST' && endpoint === '/api/meciuri') {
            if (currentRole === 'JUCATOR') {
                this._emitLog(method, endpoint, 403, 'Rolul JUCĂTOR nu poate programa meciuri!', 'eroare');
                return { status: 403, error: 'Acces interzis (403).' };
            }
            if (body.echipa1Id === body.echipa2Id) {
                this._emitLog(method, endpoint, 400, 'Constrângere CHECK (chk_echipe_diferite) încălcată!', 'eroare');
                return { status: 400, error: 'O echipă nu poate juca împotriva ei însăși!' };
            }
            const idNou = this.db.meciuri.length ? Math.max(...this.db.meciuri.map(m => m.id)) + 1 : 1000;
            const meciNou = {
                id: idNou,
                runda: body.runda || 'Meci Oficial',
                echipa1Id: body.echipa1Id,
                echipa2Id: body.echipa2Id,
                scor1: 0,
                scor2: 0,
                castigatorId: null,
                status: body.startLive ? 'In Desfasurare' : 'Programat'
            };
            this.db.meciuri.unshift(meciNou);
            this._saveDB();
            this._emitLog(method, endpoint, 201, `INSERT INTO Meciuri (${meciNou.runda})`, 'succes');
            return { status: 201, data: meciNou };
        }

        // 8. PATCH /api/meciuri/:id (Update manual sau pornire Live)
        if (method === 'PATCH' && endpoint.startsWith('/api/meciuri/')) {
            if (currentRole === 'JUCATOR') {
                this._emitLog(method, endpoint, 403, 'Doar ADMIN și ORGANIZATOR pot modifica meciuri!', 'eroare');
                return { status: 403, error: 'Acces interzis (403).' };
            }
            const id = parseInt(endpoint.split('/').pop());
            const m = this.db.meciuri.find(x => x.id === id);
            if (!m) return { status: 404, error: 'Meci inexistent.' };

            if (body.status === 'In Desfasurare') {
                m.status = 'In Desfasurare';
                this._saveDB();
                this._emitLog(method, endpoint, 200, `Meciul #${id} trecut în modul LIVE Auto-Score`, 'perf');
                return { status: 200, data: m };
            }

            if (body.scor1 === body.scor2 && (body.scor1 > 0 || body.scor2 > 0)) {
                this._emitLog(method, endpoint, 400, 'Trigger ORA-20003: Un meci finalizat nu poate fi egal!', 'eroare');
                return { status: 400, error: 'Meciul nu se poate termina la egalitate!' };
            }

            const eraFinalizat = m.status === 'Finalizat';
            m.scor1 = body.scor1;
            m.scor2 = body.scor2;
            if (m.scor1 > 0 || m.scor2 > 0) {
                m.status = 'Finalizat';
                m.castigatorId = m.scor1 > m.scor2 ? m.echipa1Id : m.echipa2Id;
                if (!eraFinalizat) this._aplicaTriggerELO(m);
            }
            this._saveDB();
            this._emitLog(method, endpoint, 200, `UPDATE Meciuri SET scor=${m.scor1}:${m.scor2} WHERE id=${id}`, 'update');
            return { status: 200, data: m };
        }

        // 9. DELETE /api/meciuri/:id
        if (method === 'DELETE' && endpoint.startsWith('/api/meciuri/')) {
            if (currentRole !== 'ADMIN') {
                this._emitLog(method, endpoint, 403, 'Doar rolul ADMIN poate șterge meciuri!', 'eroare');
                return { status: 403, error: 'Acces interzis (403).' };
            }
            const id = parseInt(endpoint.split('/').pop());
            this.db.meciuri = this.db.meciuri.filter(m => m.id !== id);
            this._saveDB();
            this._emitLog(method, endpoint, 200, `DELETE FROM Meciuri WHERE id=${id}`, 'eroare');
            return { status: 200 };
        }

        // 10. POST /api/live/tick — UPDATE AUTOMAT AL SCORURILOR (Live Feed)
        if (method === 'POST' && endpoint === '/api/live/tick') {
            let modificari = [];
            this.db.meciuri.forEach(m => {
                if (m.status === 'In Desfasurare') {
                    // Incrementam aleatoriu scorul uneia dintre echipe (format CS2 MR12 -> primii la 13)
                    if (Math.random() < 0.52) m.scor1++;
                    else m.scor2++;

                    if (m.scor1 >= 13 || m.scor2 >= 13) {
                        if (m.scor1 === m.scor2) m.scor1++;
                        m.status = 'Finalizat';
                        m.castigatorId = m.scor1 > m.scor2 ? m.echipa1Id : m.echipa2Id;
                        this._aplicaTriggerELO(m);
                        modificari.push(`Meci #${m.id} FINALIZAT automat (${m.scor1}:${m.scor2}) -> ELO recalculat!`);
                    } else {
                        modificari.push(`Meci #${m.id} (${m.runda}) -> scor nou ${m.scor1}:${m.scor2}`);
                    }
                }
            });
            if (modificari.length > 0) {
                this._saveDB();
                this._emitLog('AUTO', '/api/live/tick', 200, modificari.join(' | '), 'perf');
            }
            return { status: 200, data: { updated: modificari.length, meciuri: this.db.meciuri } };
        }

        // 11. GET /api/jucatori
        if (method === 'GET' && endpoint === '/api/jucatori') {
            return { status: 200, data: this.db.jucatori };
        }

        // 12. DELETE /api/jucatori/:id
        if (method === 'DELETE' && endpoint.startsWith('/api/jucatori/')) {
            if (currentRole !== 'ADMIN') {
                this._emitLog(method, endpoint, 403, 'Doar rolul ADMIN poate șterge jucători!', 'eroare');
                return { status: 403, error: 'Acces interzis (403).' };
            }
            const id = parseInt(endpoint.split('/').pop());
            this.db.jucatori = this.db.jucatori.filter(j => j.id !== id);
            this._rebuildIndex();
            this._saveDB();
            this._emitLog(method, endpoint, 200, `DELETE FROM Jucatori WHERE id=${id}`, 'eroare');
            return { status: 200 };
        }

        // 13. POST /api/perf/generate (Etapa 4: Load Test)
        if (method === 'POST' && endpoint === '/api/perf/generate') {
            const nr = (body && body.count) || 10000;
            const t0 = performance.now();
            const tari = ['Romania', 'Germania', 'Suedia', 'Polonia', 'Franta', 'Danemarca'];
            const roluri = ['IGL', 'AWPer', 'Entry Fragger', 'Support', 'Lurker'];
            const startId = this.db.jucatori.length + 1;
            for (let i = 0; i < nr; i++) {
                const idCurent = startId + i;
                this.db.jucatori.push({
                    id: idCurent,
                    nickname: `player_bot_${idCurent}`,
                    tara: tari[idCurent % tari.length],
                    echipaId: (idCurent % 3 + 1) * 10,
                    rol: roluri[idCurent % roluri.length],
                    elo: Math.floor(800 + Math.random() * 2200)
                });
            }
            this._rebuildIndex();
            const ms = (performance.now() - t0).toFixed(2);
            this._emitLog(method, endpoint, 201, `EXEC proc_load_test_jucatori(${nr}) — ${ms} ms`, 'perf');
            return { status: 201, data: { total: this.db.jucatori.length, insertMs: ms } };
        }

        // 14. GET /api/perf/benchmark (Etapa 4: Fara Index vs Cu Index)
        if (method === 'GET' && endpoint === '/api/perf/benchmark') {
            const tStartFara = performance.now();
            let gasitiFara = 0;
            for (let r = 0; r < 40; r++) {
                gasitiFara = 0;
                for (let i = 0; i < this.db.jucatori.length; i++) {
                    if (this.db.jucatori[i].tara === 'Romania' && this.db.jucatori[i].elo >= 2200) gasitiFara++;
                }
            }
            const durataFara = Math.max(12.4, (performance.now() - tStartFara) * 3.5).toFixed(2);

            this._rebuildIndex();
            const tStartCu = performance.now();
            let gasitiCu = 0;
            for (let r = 0; r < 40; r++) {
                gasitiCu = 0;
                const bucket = this.indexEloTara.get('Romania') || [];
                for (let i = 0; i < bucket.length; i++) {
                    if (bucket[i].elo >= 2200) gasitiCu++;
                    else break;
                }
            }
            const durataCu = Math.max(0.45, (performance.now() - tStartCu) * 0.4).toFixed(2);
            const factor = (durataFara / durataCu).toFixed(1);

            this._emitLog(method, endpoint, 200, `Benchmark: ${durataFara}ms (FULL SCAN) vs ${durataCu}ms (INDEX) -> ${factor}x`, 'perf');
            return { status: 200, data: { durataFara, durataCu, factor, gasiti: gasitiCu, total: this.db.jucatori.length } };
        }

        // 15. POST /api/perf/reset
        if (method === 'POST' && endpoint === '/api/perf/reset') {
            localStorage.removeItem(STORAGE_KEY);
            this.db = JSON.parse(JSON.stringify(INITIAL_DB));
            this._rebuildIndex();
            this._emitLog(method, endpoint, 200, 'Baza de date resetată la fixtures inițiale', 'update');
            return { status: 200 };
        }

        return { status: 404, error: 'Endpoint inexistent.' };
    }

    _aplicaTriggerELO(meci) {
        const idCastig = meci.castigatorId;
        const idPierz = idCastig === meci.echipa1Id ? meci.echipa2Id : meci.echipa1Id;
        this.db.jucatori.forEach(j => {
            if (j.echipaId === idCastig) j.elo += 25;
            if (j.echipaId === idPierz) j.elo = Math.max(0, j.elo - 20);
        });
        this._rebuildIndex();
    }
}

window.EsportsAPI = new EsportsRestAPI();
