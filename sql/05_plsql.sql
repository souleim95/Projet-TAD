-- Objectif : automatisation et contrôle de cohérence avec PL/SQL
-- Contenu : triggers, procédures, fonctions et curseurs


-- 1. TRIGGER : mise à jour automatique de la date de modification
-- Lorsqu'un matériel est modifié, la colonne date_modification
-- est automatiquement renseignée.

CREATE OR REPLACE TRIGGER trg_materiel_update_date
BEFORE UPDATE ON MATERIEL
FOR EACH ROW
BEGIN
    :NEW.date_modification := SYSDATE;
END;
/


-- 2. TRIGGER : historisation des changements d'affectation
-- Lorsqu'un matériel change de responsable, l'ancienne affectation
-- est historisée dans HISTO_AFFECTATION.

CREATE OR REPLACE TRIGGER trg_histo_affectation
AFTER UPDATE OF id_user_responsable ON MATERIEL
FOR EACH ROW
WHEN (
    OLD.id_user_responsable IS NOT NULL
    AND (
        NEW.id_user_responsable IS NULL
        OR OLD.id_user_responsable <> NEW.id_user_responsable
    )
)
BEGIN
    INSERT INTO HISTO_AFFECTATION (
        id_materiel,
        id_user,
        id_site,
        date_debut,
        date_fin
    )
    VALUES (
        :OLD.id_materiel,
        :OLD.id_user_responsable,
        :OLD.id_site,
        NVL(:OLD.date_modification, NVL(:OLD.date_creation, SYSDATE)),
        SYSDATE
    );
END;
/


-- 3. TRIGGER : contrôle de cohérence entre matériel et site utilisateur
-- Un matériel ne peut être affecté qu'à un utilisateur du même site.
-- Exemple : un matériel de Cergy ne doit pas être affecté à un utilisateur de Pau.

CREATE OR REPLACE TRIGGER trg_check_affectation_site
BEFORE INSERT OR UPDATE OF id_user_responsable ON MATERIEL
FOR EACH ROW
WHEN (NEW.id_user_responsable IS NOT NULL)
DECLARE
    v_site_user UTILISATEUR.id_site%TYPE;
BEGIN
    SELECT id_site
    INTO v_site_user
    FROM UTILISATEUR
    WHERE id_user = :NEW.id_user_responsable;

    IF v_site_user <> :NEW.id_site THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Affectation impossible : le matériel et l utilisateur ne sont pas rattachés au même site.'
        );
    END IF;
END;
/


-- 4. TRIGGER : contrôle de cohérence matériel / localisation / site
-- Une localisation rattachée à un matériel doit appartenir au même site.

CREATE OR REPLACE TRIGGER trg_check_materiel_localisation_site
BEFORE INSERT OR UPDATE OF id_site, id_localisation ON MATERIEL
FOR EACH ROW
WHEN (NEW.id_localisation IS NOT NULL)
DECLARE
    v_site_localisation LOCALISATION.id_site%TYPE;
BEGIN
    SELECT id_site
    INTO v_site_localisation
    FROM LOCALISATION
    WHERE id_localisation = :NEW.id_localisation;

    IF v_site_localisation <> :NEW.id_site THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Incohérence : le matériel et sa localisation ne sont pas rattachés au même site.'
        );
    END IF;
END;
/


-- 5. TRIGGER : contrôle de cohérence VLAN / sous-réseau / site
-- Un sous-réseau doit appartenir au même site que son VLAN.

CREATE OR REPLACE TRIGGER trg_check_sous_reseau_site
BEFORE INSERT OR UPDATE ON SOUS_RESEAU
FOR EACH ROW
DECLARE
    v_site_vlan VLAN.id_site%TYPE;
BEGIN
    SELECT id_site
    INTO v_site_vlan
    FROM VLAN
    WHERE id_vlan = :NEW.id_vlan;

    IF v_site_vlan <> :NEW.id_site THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Incohérence : le sous-réseau et le VLAN ne sont pas rattachés au même site.'
        );
    END IF;
END;
/


-- 6. TRIGGER : contrôle de cohérence IP / interface / sous-réseau
-- Une IP associée à une interface doit appartenir au même site que cette interface.

CREATE OR REPLACE TRIGGER trg_check_ip_interface_site
BEFORE INSERT OR UPDATE OF id_sous_reseau, id_interface ON ADRESSE_IP
FOR EACH ROW
WHEN (NEW.id_interface IS NOT NULL)
DECLARE
    v_site_sous_reseau SOUS_RESEAU.id_site%TYPE;
    v_site_interface SITE.id_site%TYPE;
BEGIN
    SELECT id_site
    INTO v_site_sous_reseau
    FROM SOUS_RESEAU
    WHERE id_sous_reseau = :NEW.id_sous_reseau;

    SELECT COALESCE(m.id_site, er.id_site)
    INTO v_site_interface
    FROM INTERFACE_RESEAU ir
    LEFT JOIN MATERIEL m
        ON ir.id_materiel = m.id_materiel
    LEFT JOIN EQUIPEMENT_RESEAU er
        ON ir.id_equipement = er.id_equipement
    WHERE ir.id_interface = :NEW.id_interface;

    IF v_site_interface <> v_site_sous_reseau THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Incohérence : l adresse IP et l interface ne sont pas rattachées au même site.'
        );
    END IF;
END;
/


-- 7. PROCEDURE : affecter un matériel à un utilisateur
-- Cette procédure affecte un matériel à un utilisateur.
-- Elle met aussi le statut du matériel à AFFECTE.

CREATE OR REPLACE PROCEDURE affecter_materiel (
    p_id_materiel IN NUMBER,
    p_id_user IN NUMBER
)
IS
    v_site_materiel MATERIEL.id_site%TYPE;
    v_site_user UTILISATEUR.id_site%TYPE;
BEGIN
    SELECT id_site
    INTO v_site_materiel
    FROM MATERIEL
    WHERE id_materiel = p_id_materiel;

    SELECT id_site
    INTO v_site_user
    FROM UTILISATEUR
    WHERE id_user = p_id_user;

    IF v_site_materiel <> v_site_user THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Affectation refusée : le matériel et l utilisateur appartiennent à deux sites différents.'
        );
    END IF;

    UPDATE MATERIEL
    SET id_user_responsable = p_id_user,
        statut = 'AFFECTE'
    WHERE id_materiel = p_id_materiel;

    COMMIT;
END;
/


-- 8. PROCEDURE : libérer un matériel
-- Cette procédure retire l'utilisateur responsable du matériel
-- et remet le matériel en stock.

CREATE OR REPLACE PROCEDURE liberer_materiel (
    p_id_materiel IN NUMBER
)
IS
BEGIN
    UPDATE MATERIEL
    SET id_user_responsable = NULL,
        statut = 'EN_STOCK'
    WHERE id_materiel = p_id_materiel;

    COMMIT;
END;
/


-- 9. FONCTION : compter les matériels d'un site
-- Retourne le nombre de matériels rattachés à un site.

CREATE OR REPLACE FUNCTION nb_materiels_site (
    p_id_site IN NUMBER
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM MATERIEL
    WHERE id_site = p_id_site;

    RETURN v_total;
END;
/


-- 10. FONCTION : compter les matériels par site et statut
-- Exemple : nombre de matériels EN_SERVICE à Cergy.

CREATE OR REPLACE FUNCTION nb_materiels_site_statut (
    p_id_site IN NUMBER,
    p_statut IN VARCHAR2
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM MATERIEL
    WHERE id_site = p_id_site
      AND statut = p_statut;

    RETURN v_total;
END;
/


-- 11. FONCTION : vérifier si une adresse IP est disponible
-- Retourne 1 si l'adresse IP est disponible, 0 sinon.

CREATE OR REPLACE FUNCTION ip_disponible (
    p_adresse IN VARCHAR2
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_total
    FROM ADRESSE_IP
    WHERE adresse = p_adresse
      AND active = '1';

    IF v_total = 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/


-- 12. PROCEDURE : afficher les IP actives d'un site avec un curseur
-- Cette procédure illustre l'utilisation d'un curseur explicite.
-- Elle parcourt les IP actives d'un site et les affiche avec DBMS_OUTPUT.

CREATE OR REPLACE PROCEDURE afficher_ip_actives_site (
    p_id_site IN NUMBER
)
IS
    CURSOR cur_ip IS
        SELECT
            s.code_site,
            sr.cidr,
            ip.adresse,
            ip.version_ip
        FROM ADRESSE_IP ip
        JOIN SOUS_RESEAU sr
            ON ip.id_sous_reseau = sr.id_sous_reseau
        JOIN SITE s
            ON sr.id_site = s.id_site
        WHERE s.id_site = p_id_site
          AND ip.active = '1'
        ORDER BY sr.cidr, ip.adresse;

BEGIN
    FOR rec IN cur_ip LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Site : ' || rec.code_site ||
            ' | Sous-réseau : ' || rec.cidr ||
            ' | IP : ' || rec.adresse ||
            ' | IPv' || rec.version_ip
        );
    END LOOP;
END;
/


-- 13. PROCEDURE : contrôle des incohérences réseau avec curseur
-- Cette procédure vérifie les incohérences entre les sites des VLAN
-- et les sites des sous-réseaux.

CREATE OR REPLACE PROCEDURE controle_coherence_reseau
IS
    CURSOR cur_incoherences IS
        SELECT
            sr.id_sous_reseau,
            sr.cidr,
            sr.id_site AS site_sous_reseau,
            v.id_site AS site_vlan,
            v.numero_vlan
        FROM SOUS_RESEAU sr
        JOIN VLAN v
            ON sr.id_vlan = v.id_vlan
        WHERE sr.id_site <> v.id_site;

    v_nb_incoherences NUMBER := 0;

BEGIN
    FOR rec IN cur_incoherences LOOP
        v_nb_incoherences := v_nb_incoherences + 1;

        DBMS_OUTPUT.PUT_LINE(
            'Incohérence détectée : sous-réseau ' || rec.cidr ||
            ' site=' || rec.site_sous_reseau ||
            ' VLAN=' || rec.numero_vlan ||
            ' site VLAN=' || rec.site_vlan
        );
    END LOOP;

    IF v_nb_incoherences = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucune incohérence réseau détectée.');
    ELSE
        DBMS_OUTPUT.PUT_LINE(v_nb_incoherences || ' incohérence(s) réseau détectée(s).');
    END IF;
END;
/


-- 14. PROCEDURE : synthèse du parc par site avec curseur
-- Cette procédure affiche le nombre de matériels par site et par statut.

CREATE OR REPLACE PROCEDURE synthese_parc_par_site
IS
    CURSOR cur_synthese IS
        SELECT
            s.code_site,
            s.nom AS nom_site,
            m.statut,
            COUNT(*) AS nb_materiels
        FROM SITE s
        JOIN MATERIEL m
            ON s.id_site = m.id_site
        GROUP BY s.code_site, s.nom, m.statut
        ORDER BY s.code_site, m.statut;

BEGIN
    FOR rec IN cur_synthese LOOP
        DBMS_OUTPUT.PUT_LINE(
            'Site : ' || rec.code_site ||
            ' | Statut : ' || rec.statut ||
            ' | Nombre de matériels : ' || rec.nb_materiels
        );
    END LOOP;
END;
/
