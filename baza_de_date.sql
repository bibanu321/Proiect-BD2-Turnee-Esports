-- ==========================================================
-- ACTUALIZARE AUTOMATA SCORURI (PROCEDURA + JOB AUTOMAT)
-- ==========================================================

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

CREATE OR REPLACE PROCEDURE proc_actualizare_automata_scor AS
BEGIN
    FOR m IN (SELECT id_meci, scor_echipa1, scor_echipa2 FROM Meciuri WHERE status_meci = 'Programat') LOOP
        IF DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN
            UPDATE Meciuri
            SET scor_echipa1 = scor_echipa1 + 1,
                status_meci = CASE WHEN scor_echipa1 + 1 >= 13 THEN 'Finalizat' ELSE status_meci END
            WHERE id_meci = m.id_meci;
        ELSE
            UPDATE Meciuri
            SET scor_echipa2 = scor_echipa2 + 1,
                status_meci = CASE WHEN scor_echipa2 + 1 >= 13 THEN 'Finalizat' ELSE status_meci END
            WHERE id_meci = m.id_meci;
        END IF;
    END LOOP;
    COMMIT;
END;
/

-- ==========================================================
-- ETAPA 5: VEDERE PENTRU RAPOARTE (EXPORT PDF / CSV / EXCEL)
-- ==========================================================

CREATE OR REPLACE VIEW V_Raport_Meciuri_Detaliat AS
SELECT 
    m.id_meci,
    t.titlu AS turneu,
    m.runda,
    e1.nume_echipa AS echipa_1,
    m.scor_echipa1,
    m.scor_echipa2,
    e2.nume_echipa AS echipa_2,
    NVL(ec.nume_echipa, 'In desfasurare') AS castigator,
    m.status_meci
FROM Meciuri m
JOIN Turnee t ON m.id_turneu = t.id_turneu
JOIN Echipe e1 ON m.id_echipa1 = e1.id_echipa
JOIN Echipe e2 ON m.id_echipa2 = e2.id_echipa
LEFT JOIN Echipe ec ON m.id_castigator = ec.id_echipa;
