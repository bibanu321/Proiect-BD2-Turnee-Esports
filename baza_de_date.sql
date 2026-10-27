-- 1. CREAREA TABELELOR (DDL)
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

-- 2. POPULAREA CU DATE (DML)
INSERT INTO Jucatori VALUES (1, 's1mple_ro', 'alex@student.ro', 2150, 'Romania', SYSDATE-60);
INSERT INTO Jucatori VALUES (2, 'iM_legend', 'mihai@student.ro', 2080, 'Romania', SYSDATE-55);
INSERT INTO Jucatori VALUES (3, 'karrigan_gl', 'andrei@student.ro', 1920, 'Romania', SYSDATE-50);
INSERT INTO Jucatori VALUES (4, 'm0NESY_peek', 'vlad@student.ro', 2210, 'Romania', SYSDATE-45);
INSERT INTO Jucatori VALUES (5, 'niko_deagle', 'cristi@student.ro', 1990, 'Romania', SYSDATE-40);
INSERT INTO Jucatori VALUES (6, 'zywoo_ace', 'bogdan@student.ro', 2180, 'Romania', SYSDATE-35);

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

-- 3. VIEW CLASAMENT
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

-- 4. TRIGGER 1: VALIDARE CAPACITATE TURNEU
CREATE OR REPLACE TRIGGER trg_validare_capacitate_turneu
BEFORE INSERT ON Inscrieri_Turneu
FOR EACH ROW
DECLARE
    v_echipe_inscrise NUMBER;
    v_max_echipe NUMBER;
    v_status VARCHAR2(30);
BEGIN
    SELECT max_echipe, status INTO v_max_echipe, v_status
    FROM Turnee
    WHERE id_turneu = :NEW.id_turneu;
    IF v_status != 'Inscrieri Deschise' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Eroare Trigger: Inscrierile sunt inchise!');
    END IF;
    SELECT COUNT(*) INTO v_echipe_inscrise
    FROM Inscrieri_Turneu
    WHERE id_turneu = :NEW.id_turneu;
    IF v_echipe_inscrise >= v_max_echipe THEN
        RAISE_APPLICATION_ERROR(-20002, 'Eroare Trigger: Turneul este plin!');
    END IF;
END;
/

-- 5. TRIGGER 2: CALCUL AUTOMAT CASTIGATOR SI ELO
CREATE OR REPLACE TRIGGER trg_finalizare_meci_elo
BEFORE UPDATE OF scor_echipa1, scor_echipa2, status_meci ON Meciuri
FOR EACH ROW
BEGIN
    IF :NEW.status_meci = 'Finalizat' AND :OLD.status_meci != 'Finalizat' THEN
        IF :NEW.scor_echipa1 > :NEW.scor_echipa2 THEN
            :NEW.id_castigator := :NEW.id_echipa1;
            UPDATE Jucatori SET rank_elo = rank_elo + 25
            WHERE id_jucator IN (SELECT id_jucator FROM Membri_Echipa WHERE id_echipa = :NEW.id_echipa1);
            UPDATE Jucatori SET rank_elo = GREATEST(0, rank_elo - 20)
            WHERE id_jucator IN (SELECT id_jucator FROM Membri_Echipa WHERE id_echipa = :NEW.id_echipa2);
        ELSIF :NEW.scor_echipa2 > :NEW.scor_echipa1 THEN
            :NEW.id_castigator := :NEW.id_echipa2;
            UPDATE Jucatori SET rank_elo = rank_elo + 25
            WHERE id_jucator IN (SELECT id_jucator FROM Membri_Echipa WHERE id_echipa = :NEW.id_echipa2);
            UPDATE Jucatori SET rank_elo = GREATEST(0, rank_elo - 20)
            WHERE id_jucator IN (SELECT id_jucator FROM Membri_Echipa WHERE id_echipa = :NEW.id_echipa1);
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Eroare Trigger: Meciul nu se poate termina la egalitate!');
        END IF;
    END IF;
END;
/

-- 6. PROCEDURA STOCATA CU TRANZACTIE
CREATE OR REPLACE PROCEDURE proc_inregistreaza_scor (
    p_id_meci IN NUMBER,
    p_scor1 IN NUMBER,
    p_scor2 IN NUMBER
) AS
BEGIN
    UPDATE Meciuri
    SET scor_echipa1 = p_scor1,
        scor_echipa2 = p_scor2,
        status_meci = 'Finalizat'
    WHERE id_meci = p_id_meci;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

-- 7. TESTARE AUTOMATA PROCEDURA SI AFISARE CLASAMENT
BEGIN
    proc_inregistreaza_scor(1001, 16, 12);
END;
/

SELECT * FROM V_Clasament_Echipe ORDER BY elo_mediu_echipa DESC;