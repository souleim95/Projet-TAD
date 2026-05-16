-- =============================================================================
-- Nom : 10_performance_comparison.sql
-- Objectif : Simuler la comparaison de temps d'exécution (Ancienne vs Nouvelle base)
-- =============================================================================

SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

DECLARE
    v_start_time    TIMESTAMP;
    v_end_time      TIMESTAMP;
    v_time_ref      NUMBER;
    v_time_opt      NUMBER;
    v_gain          NUMBER;
    v_dummy         NUMBER;
    
    -- Fonction pour calculer la différence en millisecondes
    FUNCTION calc_ms(p_start TIMESTAMP, p_end TIMESTAMP) RETURN NUMBER IS
        v_diff INTERVAL DAY TO SECOND;
    BEGIN
        v_diff := p_end - p_start;
        RETURN EXTRACT(DAY FROM v_diff) * 24 * 60 * 60 * 1000 
             + EXTRACT(HOUR FROM v_diff) * 60 * 60 * 1000 
             + EXTRACT(MINUTE FROM v_diff) * 60 * 1000 
             + EXTRACT(SECOND FROM v_diff) * 1000;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Requête                      | Temps référence | Temps optimisé | Gain %');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------');

    -- ==========================================
    -- TEST 1 : Recherche Parc Cergy (Filtre complexe)
    -- ==========================================
    -- Référence (Sans Index - Simulation GLPI générique)
    v_start_time := SYSTIMESTAMP;
    FOR i IN 1..1000 LOOP
        SELECT /*+ FULL(m) */ COUNT(*) INTO v_dummy FROM MATERIEL m 
        WHERE id_site = 1 AND type_materiel = 'PORTABLE' AND statut = 'EN_SERVICE';
    END LOOP;
    v_end_time := SYSTIMESTAMP;
    v_time_ref := calc_ms(v_start_time, v_end_time);

    -- Optimisé (Utilise votre IDX_MATERIEL_SITE_TYPE_STATUT)
    v_start_time := SYSTIMESTAMP;
    FOR i IN 1..1000 LOOP
        SELECT COUNT(*) INTO v_dummy FROM MATERIEL m 
        WHERE id_site = 1 AND type_materiel = 'PORTABLE' AND statut = 'EN_SERVICE';
    END LOOP;
    v_end_time := SYSTIMESTAMP;
    v_time_opt := calc_ms(v_start_time, v_end_time);

    v_gain := ROUND(((v_time_ref - v_time_opt) / v_time_ref) * 100);
    DBMS_OUTPUT.PUT_LINE(RPAD('Parc Cergy (1000x)', 29) || '| ' || 
                         RPAD(v_time_ref || ' ms', 16) || '| ' || 
                         RPAD(v_time_opt || ' ms', 15) || '| ' || 
                         v_gain || ' %');


    -- ==========================================
    -- TEST 2 : Utilisateurs Pau (Filtre statut)
    -- ==========================================
    -- Référence
    v_start_time := SYSTIMESTAMP;
    FOR i IN 1..2000 LOOP
        SELECT /*+ FULL(u) */ COUNT(*) INTO v_dummy FROM UTILISATEUR u 
        WHERE id_site = 2 AND statut = 'ACTIF';
    END LOOP;
    v_end_time := SYSTIMESTAMP;
    v_time_ref := calc_ms(v_start_time, v_end_time);

    -- Optimisé (Utilise votre IDX_USER_SITE_STATUT)
    v_start_time := SYSTIMESTAMP;
    FOR i IN 1..2000 LOOP
        SELECT COUNT(*) INTO v_dummy FROM UTILISATEUR u 
        WHERE id_site = 2 AND statut = 'ACTIF';
    END LOOP;
    v_end_time := SYSTIMESTAMP;
    v_time_opt := calc_ms(v_start_time, v_end_time);

    v_gain := ROUND(((v_time_ref - v_time_opt) / v_time_ref) * 100);
    DBMS_OUTPUT.PUT_LINE(RPAD('Utilisateurs Pau (2000x)', 29) || '| ' || 
                         RPAD(v_time_ref || ' ms', 16) || '| ' || 
                         RPAD(v_time_opt || ' ms', 15) || '| ' || 
                         v_gain || ' %');


    -- ==========================================
    -- TEST 3 : Dashboard Global (Jointures vs MV)
    -- ==========================================
    -- Référence (Jointure directe sur la vue standard)
    v_start_time := SYSTIMESTAMP;
    FOR i IN 1..500 LOOP
        SELECT COUNT(*) INTO v_dummy FROM V_PARC_GLOBAL 
        WHERE statut_materiel = 'MAINTENANCE';
    END LOOP;
    v_end_time := SYSTIMESTAMP;
    v_time_ref := calc_ms(v_start_time, v_end_time);

    -- Optimisé (Utilise la Vue Matérialisée de BDDR)
    v_start_time := SYSTIMESTAMP;
    FOR i IN 1..500 LOOP
        SELECT COUNT(*) INTO v_dummy FROM MV_PARC_GLOBAL 
        WHERE statut_materiel = 'MAINTENANCE';
    END LOOP;
    v_end_time := SYSTIMESTAMP;
    v_time_opt := calc_ms(v_start_time, v_end_time);

    v_gain := ROUND(((v_time_ref - v_time_opt) / v_time_ref) * 100);
    DBMS_OUTPUT.PUT_LINE(RPAD('Dashboard global (500x)', 29) || '| ' || 
                         RPAD(v_time_ref || ' ms', 16) || '| ' || 
                         RPAD(v_time_opt || ' ms', 15) || '| ' || 
                         v_gain || ' %');

    DBMS_OUTPUT.PUT_LINE('---------------------------------------------------------------------------------');
END;
/