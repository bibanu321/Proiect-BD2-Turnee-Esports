-- ==========================================================
-- PROIECT BAZE DE DATE AVANSATE (ETAPELE 1, 2, 3 SI 4)
-- Tema: Platforma de Gestiune a Turneelor de Esports (CS2)
-- ==========================================================

-- ==========================================================
-- ETAPA 1: MODELARE BAZA DE DATE (7 Tabele, Relatii, Fixtures)
-- ==========================================================

CREATE TABLE Jucatori (
    id_jucator NUMBER PRIMARY KEY,
    nickname VARCHAR2(50) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL UNIQUE,
    rank_elo NUMBER DEFAULT 1000 CHECK (rank_elo >= 0),
    tara VARCHAR2(50),
    data_inregistrare DATE DEFAULT SYSDATE
);

CREATE TABLE Echipe (
    id_echipa NUMBER PRIMARY KEY,
    nume_echipa VARCHAR2(100) NOT NULL UNIQUE,
    tag VARCHAR2(10) NOT NULL,
    id_capitan NUMBER,
    data_creare DATE DEFAULT SYSDATE,
    CONSTRAINT fk_echipa_capitan FOREIGN KEY (id_capitan) REFERENCES Jucatori(id_jucator)
);

CREATE TABLE Membri_Echipa (
    id_echipa NUMBER,
    id_jucator NUMBER,
    rol VARCHAR2(30) CHECK (rol IN ('IGL', 'AWPer', 'Entry Fragger', 'Support', 'Lurker')),
    data_alaturare DATE DEFAULT SYSDATE,
    CONSTRAINT pk_membri PRIMARY KEY (id_echipa, id_jucator),
    CONSTRAINT fk_membri_echipa FOREIGN KEY (id_echipa) REFERENCES Echipe(id_echipa) ON DELETE CASCADE,
    CONSTRAINT fk_membri_jucator FOREIGN KEY (id_jucator) REFERENCES Jucatori(id_jucator) ON DELETE CASCADE
);

CREATE TABLE Turnee (
    id_turneu NUMBER PRIMARY KEY,
    titlu VARCHAR2(150) NOT NULL,
    joc VARCHAR2(50) DEFAULT 'Counter-Strike 2' NOT NULL,
    max_echipe NUMBER NOT NULL CHECK (max_echipe IN (4, 8, 16, 32)),
    fond_premiere NUMBER(10, 2) CHECK (fond_premiere >= 0),
    data_start DATE,
    data_sfarsit DATE,
    status VARCHAR2(30) DEFAULT 'Inscrieri Deschise' CHECK (status IN ('Inscrieri Deschise', 'In Desfasurare', 'Finalizat'))
);

CREATE TABLE Inscrieri_Turneu (
    id_turneu NUMBER,
    id_echipa NUMBER,
    seed_nr NUMBER,
    data_inscriere DATE DEFAULT SYSDATE,
    CONSTRAINT pk_inscrieri PRIMARY KEY (id_turneu, id_echipa),
    CONSTRAINT fk_inscriere_turneu FOREIGN KEY (id_turneu) REFERENCES Turnee(id_turneu) ON DELETE CASCADE,
    CONSTRAINT fk_inscriere_echipa FOREIGN KEY (id_echipa) REFERENCES Echipe(id_echipa) ON DELETE CASCADE
);

CREATE TABLE Meciuri (
    id_meci NUMBER PRIMARY KEY,
    id_turneu NUMBER NOT NULL,
    id_echipa1 NUMBER NOT NULL,
    id_echipa2 NUMBER NOT NULL,
    runda VARCHAR2(50) NOT NULL,
    scor_echipa1 NUMBER DEFAULT 0 CHECK (scor_echipa1 >= 0),
    scor_echipa2 NUMBER DEFAULT 0 CHECK (scor_echipa2 >= 0),
    id_castigator NUMBER,
    status_meci VARCHAR2(30) DEFAULT 'Programat' CHECK (status_meci IN ('Programat', 'Finalizat')),
    data_ora DATE DEFAULT SYSDATE,
    CONSTRAINT fk_meci_turneu FOREIGN KEY (id_turneu) REFERENCES Turnee(id_turneu) ON DELETE CASCADE,
    CONSTRAINT fk_meci_echipa1 FOREIGN KEY (id_echipa1) REFERENCES Echipe(id_echipa),
    CONSTRAINT fk_meci_echipa2 FOREIGN KEY (id_echipa2) REFERENCES Echipe(id_echipa),
    CONSTRAINT fk_meci_castigator FOREIGN KEY (id_castigator) REFERENCES Echipe(id_echipa),
    CONSTRAINT chk_echipe_diferite CHECK (id_echipa1 != id_echipa2)
);

-- ==========================================================
-- ETAPA 3: AUTENTIFICARE SI CONTROLUL ACCESULUI (3 ROLURI)
-- ==========================================================

CREATE TABLE Utilizatori (
    id_utilizator NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    parola_hash VARCHAR2(128) NOT NULL,
    rol VARCHAR2(30) NOT NULL CHECK (rol IN ('ADMIN', 'ORGANIZATOR', 'JUCATOR')),
    id_jucator_asociat NUMBER,
    ultimul_login DATE DEFAULT SYSDATE,
    CONSTRAINT fk_user_jucator FOREIGN KEY (id_jucator_asociat) REFERENCES Jucatori(id_jucator) ON DELETE SET NULL
);

-- ==========================================================
-- POPULARE CU FIXTURES (DATE INITIALE)
-- ==========================================================

INSERT INTO Jucatori VALUES (1, 's1mple_ro', 'alex@student.ro', 2150, 'Romania', SYSDATE-60);
INSERT INTO Jucatori VALUES (2, 'iM_legend', 'mihai@student.ro', 2080, 'Romania', SYSDATE-55);
INSERT INTO Jucatori VALUES (3, 'karrigan_gl', 'andrei@student.ro', 1920, 'Romania', SYSDATE-50);
INSERT INTO Jucatori VALUES (4, 'm0NESY_peek', 'vlad@student.ro', 2210, 'Romania', SYSDATE-45);
INSERT INTO Jucatori VALUES (5, 'niko_deagle', 'cristi@student.ro', 1990, 'Romania', SYSDATE-40);
INSERT INTO Jucatori VALUES (6, 'zywoo_ace', 'bogdan@student.ro', 2180, 'Romania', SYSDATE-35);

-- Conturi pentru cele 3 roluri cerute la Etapa 3:
INSERT INTO Utilizatori VALUES (1, 'admin_cosmin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'ADMIN', NULL, SYSDATE);
INSERT INTO Utilizatori VALUES (2, 'org_faceit', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'ORGANIZATOR', NULL, SYSDATE);
INSERT INTO Utilizatori VALUES (3, 'capitan_s1mple', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'JUCATOR', 1, SYSDATE);

INSERT INTO Echipe VALUES (10, 'Danube Wolves', 'DW', 1, SYSDATE-30);
INSERT INTO Echipe VALUES (20, 'Vortex Gaming', 'VTX', 4, SYSDATE-28);
INSERT INTO Echipe VALUES (30, 'Nexus Titans', 'NXS', 6, SYSDATE-25);

INSERT INTO Membri_Echipa VALUES (10, 1, 'AWPer', SYSDATE-30);
INSERT INTO Membri_Echipa VALUES (10, 2, 'Entry Fragger', SYSDATE-29);
INSERT INTO Membri_Echipa VALUES (10, 3, 'IGL', SYSDATE-29);
INSERT INTO Membri_Echipa VALUES (20, 4, 'AWPer', SYSDATE-28);
INSERT INTO Membri_Echipa VALUES (20, 5, 'Entry Fragger', SYSDATE-27);
INSERT INTO Membri_Echipa VALUES (30, 6, 'IGL', SYSDATE-25);

INSERT INTO Turnee VALUES (100, 'Romanian Pro League - Season 1', 'Counter-Strike 2', 8, 5000.00, SYSDATE, SYSDATE+7, 'In Desfasurare');
INSERT INTO Turnee VALUES (101, 'Winter Faceit Cup', 'Counter-Strike 2', 4, 1500.00, SYSDATE+14, SYSDATE+16, 'Inscrieri Deschise');

INSERT INTO Inscrieri_Turneu VALUES (100, 10, 1, SYSDATE-10);
INSERT INTO Inscrieri_Turneu VALUES (100, 20, 2, SYSDATE-9);
INSERT INTO Inscrieri_Turneu VALUES (100, 30, 3, SYSDATE-8);

INSERT INTO Meciuri VALUES (1000, 100, 10, 20, 'Semifinala 1', 13, 9, 10, 'Finalizat', SYSDATE-1);
INSERT INTO Meciuri VALUES (1001, 100, 10, 30, 'Finala Mare', 0, 0, NULL, 'Programat', SYSDATE+1);
COMMIT;

-- ==========================================================
-- ETAPA 4: PERFORMANTA - INDECSI SI LOAD TEST
-- ==========================================================

-- 1. Crearea indecsilor B-Tree pentru optimizarea cautarilor frecvente si a JOIN-urilor:
CREATE INDEX idx_jucatori_elo_tara ON Jucatori(rank_elo DESC, tara);
CREATE INDEX idx_meciuri_turneu_status ON Meciuri(id_turneu, status_meci);
CREATE INDEX idx_membri_jucator ON Membri_Echipa(id_jucator);
CREATE INDEX idx_utilizatori_rol ON Utilizatori(rol);

-- 2. Procedura de Load Testing (Generare volum mare de date + masurare timp de raspuns):
CREATE OR REPLACE PROCEDURE proc_load_test_jucatori (
    p_numar_inregistrari IN NUMBER DEFAULT 10000
) AS
    v_start_time NUMBER;
    v_end_time NUMBER;
    v_count NUMBER;
BEGIN
    v_start_time := DBMS_UTILITY.GET_TIME;
    FOR i IN 100 .. (100 + p_numar_inregistrari - 1) LOOP
        INSERT INTO Jucatori (id_jucator, nickname, email, rank_elo, tara, data_inregistrare)
        VALUES (
            i,
            'player_bot_' || i,
            'bot_' || i || '@faceit.ro',
            TRUNC(DBMS_RANDOM.VALUE(800, 3000)),
            CASE MOD(i, 4) WHEN 0 THEN 'Romania' WHEN 1 THEN 'Germania' WHEN 2 THEN 'Suedia' ELSE 'Polonia' END,
            SYSDATE - MOD(i, 365)
        );
    END LOOP;
    COMMIT;
    v_end_time := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('Load Test INSERT (' || p_numar_inregistrari || ' randuri): ' || (v_end_time - v_start_time) * 10 || ' ms');

    -- Testam interogarea optimizata prin indexul compus idx_jucatori_elo_tara
    v_start_time := DBMS_UTILITY.GET_TIME;
    SELECT COUNT(*) INTO v_count
    FROM Jucatori
    WHERE rank_elo >= 2200 AND tara = 'Romania';
    v_end_time := DBMS_UTILITY.GET_TIME;
    DBMS_OUTPUT.PUT_LINE('Load Test SELECT cu INDEX (Rezultate: ' || v_count || '): ' || (v_end_time - v_start_time) * 10 || ' ms');
END;
/

-- ==========================================================
-- ELEMENTE SUPLIMENTARE BD2: VIEW, TRIGGERE SI PROCEDURA SCOR
-- ==========================================================

CREATE OR REPLACE VIEW V_Clasament_Echipe AS
SELECT 
    e.id_echipa,
    e.nume_echipa,
    e.tag,
    j.nickname AS capitan,
    COUNT(DISTINCT m.id_jucator) AS nr_jucatori,
    ROUND(AVG(jm.rank_elo), 0) AS elo_mediu_echipa,
    (SELECT COUNT(*) FROM Meciuri mc WHERE mc.id_castigator = e.id_echipa) AS meciuri_castigate
FROM Echipe e
LEFT JOIN Jucatori j ON e.id_capitan = j.id_jucator
LEFT JOIN Membri_Echipa m ON e.id_echipa = m.id_echipa
LEFT JOIN Jucatori jm ON m.id_jucator = jm.id_jucator
GROUP BY e.id_echipa, e.nume_echipa, e.tag, j.nickname;

CREATE OR REPLACE TRIGGER trg_ finalizare_meci_elo
BEFORE UPDATE OF scor_echipa1, scor_echipa2, status_meci ON Meciuri
FOR EACH ROW
BEGIN
    IF :NEW.status_meci = 'Finalizat' AND :OLD.status_meci != 'Finalizat' THEN
        IF :NEW.scor_echipa1 > :NEW.scor_echipa2 THEN
            :NEW.id_castigator := :NEW.id_echipa1;
        ELSIF :NEW.scor_echipa2 > :NEW.scor_echipa1 THEN
            :NEW.id_castigator := :NEW.id_echipa2;
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Eroare Trigger: Meciul nu se poate termina la egalitate!');
        END IF;
    END IF;
END;
/
