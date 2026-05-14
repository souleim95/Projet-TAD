-- Jeu de données pour les tests de performance

SET SERVEROUTPUT ON
SET FEEDBACK ON
SET DEFINE OFF

-- 1. Nettoyage des données opérationnelles

DELETE FROM CONNEXION;
DELETE FROM ADRESSE_IP;
DELETE FROM INTERFACE_RESEAU;
DELETE FROM HISTO_AFFECTATION;
DELETE FROM MATERIEL;
DELETE FROM USER_ROLE_SITE;
DELETE FROM UTILISATEUR;
DELETE FROM SOUS_RESEAU;
DELETE FROM VLAN;
DELETE FROM EQUIPEMENT_RESEAU;
DELETE FROM LOCALISATION;
COMMIT;


-- 2. Contrôle des référentiels

DECLARE
    v_id_cergy SITE.id_site%TYPE;
    v_id_pau SITE.id_site%TYPE;
BEGIN
    SELECT id_site INTO v_id_cergy
    FROM SITE
    WHERE code_site = 'CERGY';

    SELECT id_site INTO v_id_pau
    FROM SITE
    WHERE code_site = 'PAU';

    IF v_id_cergy <> 1 OR v_id_pau <> 2 THEN
        RAISE_APPLICATION_ERROR(
            -20100,
            'Référentiel SITE invalide : Cergy doit avoir id_site=1 et Pau id_site=2.'
        );
    END IF;
END;
/


-- 3. Insertion des données de test

DECLARE
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

    v_users_cergy       t_ids;
    v_users_pau         t_ids;
    v_locs_cergy        t_ids;
    v_locs_pau          t_ids;
    v_materiels_cergy   t_ids;
    v_materiels_pau     t_ids;
    v_equipements_cergy t_ids;
    v_equipements_pau   t_ids;
    v_interfaces_cergy  t_ids;
    v_interfaces_pau    t_ids;
    v_vlans_cergy       t_ids;
    v_vlans_pau         t_ids;
    v_sr_cergy          t_ids;
    v_sr_pau            t_ids;
    v_hosts_cergy       t_ids;
    v_hosts_pau         t_ids;

    v_role_admin        ROLE.id_role%TYPE;
    v_role_technicien   ROLE.id_role%TYPE;
    v_role_lecture      ROLE.id_role%TYPE;

    v_role_id           NUMBER;
    v_user_id           NUMBER;
    v_loc_id            NUMBER;
    v_if_id             NUMBER;
    v_new_id            NUMBER;
    v_status            VARCHAR2(30);
    v_type_materiel     VARCHAR2(40);
    v_if_cergy_count    NUMBER := 0;
    v_if_pau_count      NUMBER := 0;
    v_vlan_index        NUMBER;
    v_host              NUMBER;

    FUNCTION mac_addr(p_site IN NUMBER, p_index IN NUMBER)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN
            '02:' ||
            LPAD(p_site, 2, '0') || ':' ||
            LPAD(MOD(p_index, 100), 2, '0') || ':' ||
            LPAD(MOD(TRUNC(p_index / 100), 100), 2, '0') || ':' ||
            LPAD(MOD(TRUNC(p_index / 10000), 100), 2, '0') || ':' ||
            LPAD(MOD(TRUNC(p_index / 1000000), 100), 2, '0');
    END;
BEGIN
    SELECT id_role INTO v_role_admin
    FROM ROLE
    WHERE code_role = 'ADMIN';

    SELECT id_role INTO v_role_technicien
    FROM ROLE
    WHERE code_role = 'TECHNICIEN';

    SELECT id_role INTO v_role_lecture
    FROM ROLE
    WHERE code_role = 'LECTURE';

    FOR i IN 1..60 LOOP
        INSERT INTO LOCALISATION (id_site, batiment, salle)
        VALUES (1, 'CERGY-BAT-' || (MOD(i - 1, 6) + 1), 'S' || LPAD(i, 3, '0'))
        RETURNING id_localisation INTO v_new_id;
        v_locs_cergy(i) := v_new_id;

        INSERT INTO LOCALISATION (id_site, batiment, salle)
        VALUES (2, 'PAU-BAT-' || (MOD(i - 1, 4) + 1), 'S' || LPAD(i, 3, '0'))
        RETURNING id_localisation INTO v_new_id;
        v_locs_pau(i) := v_new_id;
    END LOOP;

    FOR i IN 1..500 LOOP
        INSERT INTO UTILISATEUR (login, nom, prenom, email, statut, id_site)
        VALUES (
            'cergy.user' || i,
            'NOM_CERGY_' || i,
            'PRENOM_CERGY_' || i,
            'cergy.user' || i || '@cy-tech.fr',
            CASE
                WHEN MOD(i, 37) = 0 THEN 'SUSPENDU'
                WHEN MOD(i, 10) = 0 THEN 'INACTIF'
                ELSE 'ACTIF'
            END,
            1
        )
        RETURNING id_user INTO v_new_id;
        v_users_cergy(i) := v_new_id;

        v_role_id :=
            CASE
                WHEN MOD(i, 20) = 0 THEN v_role_admin
                WHEN MOD(i, 3) = 0 THEN v_role_technicien
                ELSE v_role_lecture
            END;

        INSERT INTO USER_ROLE_SITE (id_user, id_role, id_site, date_debut)
        VALUES (v_users_cergy(i), v_role_id, 1, SYSDATE - MOD(i, 365));

        INSERT INTO UTILISATEUR (login, nom, prenom, email, statut, id_site)
        VALUES (
            'pau.user' || i,
            'NOM_PAU_' || i,
            'PRENOM_PAU_' || i,
            'pau.user' || i || '@cy-tech.fr',
            CASE
                WHEN MOD(i, 41) = 0 THEN 'SUSPENDU'
                WHEN MOD(i, 12) = 0 THEN 'INACTIF'
                ELSE 'ACTIF'
            END,
            2
        )
        RETURNING id_user INTO v_new_id;
        v_users_pau(i) := v_new_id;

        v_role_id :=
            CASE
                WHEN MOD(i, 25) = 0 THEN v_role_admin
                WHEN MOD(i, 4) = 0 THEN v_role_technicien
                ELSE v_role_lecture
            END;

        INSERT INTO USER_ROLE_SITE (id_user, id_role, id_site, date_debut)
        VALUES (v_users_pau(i), v_role_id, 2, SYSDATE - MOD(i, 365));
    END LOOP;

    FOR i IN 1..20 LOOP
        INSERT INTO VLAN (numero_vlan, nom, id_site)
        VALUES (1000 + i, 'CERGY-VLAN-' || i, 1)
        RETURNING id_vlan INTO v_new_id;
        v_vlans_cergy(i) := v_new_id;

        INSERT INTO SOUS_RESEAU (cidr, passerelle, id_vlan, id_site)
        VALUES ('10.1.' || i || '.0/24', '10.1.' || i || '.1', v_vlans_cergy(i), 1)
        RETURNING id_sous_reseau INTO v_new_id;
        v_sr_cergy(i) := v_new_id;

        v_hosts_cergy(i) := 10;

        INSERT INTO VLAN (numero_vlan, nom, id_site)
        VALUES (2000 + i, 'PAU-VLAN-' || i, 2)
        RETURNING id_vlan INTO v_new_id;
        v_vlans_pau(i) := v_new_id;

        INSERT INTO SOUS_RESEAU (cidr, passerelle, id_vlan, id_site)
        VALUES ('10.2.' || i || '.0/24', '10.2.' || i || '.1', v_vlans_pau(i), 2)
        RETURNING id_sous_reseau INTO v_new_id;
        v_sr_pau(i) := v_new_id;

        v_hosts_pau(i) := 10;
    END LOOP;

    FOR i IN 1..30 LOOP
        INSERT INTO EQUIPEMENT_RESEAU (nom, type_equipement, ip_mgmt, id_site)
        VALUES (
            'SW-CERGY-' || LPAD(i, 3, '0'),
            CASE WHEN MOD(i, 5) = 0 THEN 'ROUTEUR' ELSE 'SWITCH' END,
            '172.16.1.' || i,
            1
        )
        RETURNING id_equipement INTO v_new_id;
        v_equipements_cergy(i) := v_new_id;

        INSERT INTO EQUIPEMENT_RESEAU (nom, type_equipement, ip_mgmt, id_site)
        VALUES (
            'SW-PAU-' || LPAD(i, 3, '0'),
            CASE WHEN MOD(i, 5) = 0 THEN 'ROUTEUR' ELSE 'SWITCH' END,
            '172.16.2.' || i,
            2
        )
        RETURNING id_equipement INTO v_new_id;
        v_equipements_pau(i) := v_new_id;
    END LOOP;

    FOR i IN 1..3000 LOOP
        v_status :=
            CASE
                WHEN MOD(i, 20) = 0 THEN 'MAINTENANCE'
                WHEN MOD(i, 20) = 1 THEN 'EN_STOCK'
                WHEN MOD(i, 20) = 2 THEN 'HS'
                WHEN MOD(i, 5) = 0 THEN 'AFFECTE'
                ELSE 'EN_SERVICE'
            END;

        v_type_materiel :=
            CASE MOD(i, 4)
                WHEN 0 THEN 'POSTE'
                WHEN 1 THEN 'PORTABLE'
                WHEN 2 THEN 'SERVEUR'
                ELSE 'IMPRIMANTE'
            END;

        v_user_id :=
            CASE
                WHEN v_status IN ('EN_STOCK', 'HS') THEN NULL
                ELSE v_users_cergy(MOD(i - 1, 500) + 1)
            END;

        v_loc_id := v_locs_cergy(MOD(i - 1, 60) + 1);

        INSERT INTO MATERIEL (
            inventaire,
            nom,
            type_materiel,
            statut,
            id_site,
            id_localisation,
            id_user_responsable,
            date_creation
        )
        VALUES (
            'CGY-MAT-' || LPAD(i, 6, '0'),
            'Materiel Cergy ' || i,
            v_type_materiel,
            v_status,
            1,
            v_loc_id,
            v_user_id,
            SYSDATE - MOD(i, 1200)
        )
        RETURNING id_materiel INTO v_new_id;
        v_materiels_cergy(i) := v_new_id;

        INSERT INTO INTERFACE_RESEAU (nom, mac, debit_mbps, mtu, id_materiel)
        VALUES ('eth0', mac_addr(1, i), 1000, 1500, v_materiels_cergy(i))
        RETURNING id_interface INTO v_if_id;

        v_if_cergy_count := v_if_cergy_count + 1;
        v_interfaces_cergy(v_if_cergy_count) := v_if_id;

        v_user_id :=
            CASE
                WHEN v_status IN ('EN_STOCK', 'HS') THEN NULL
                ELSE v_users_pau(MOD(i - 1, 500) + 1)
            END;

        v_loc_id := v_locs_pau(MOD(i - 1, 60) + 1);

        INSERT INTO MATERIEL (
            inventaire,
            nom,
            type_materiel,
            statut,
            id_site,
            id_localisation,
            id_user_responsable,
            date_creation
        )
        VALUES (
            'PAU-MAT-' || LPAD(i, 6, '0'),
            'Materiel Pau ' || i,
            v_type_materiel,
            v_status,
            2,
            v_loc_id,
            v_user_id,
            SYSDATE - MOD(i, 1200)
        )
        RETURNING id_materiel INTO v_new_id;
        v_materiels_pau(i) := v_new_id;

        INSERT INTO INTERFACE_RESEAU (nom, mac, debit_mbps, mtu, id_materiel)
        VALUES ('eth0', mac_addr(2, i), 1000, 1500, v_materiels_pau(i))
        RETURNING id_interface INTO v_if_id;

        v_if_pau_count := v_if_pau_count + 1;
        v_interfaces_pau(v_if_pau_count) := v_if_id;
    END LOOP;

    FOR i IN 1..30 LOOP
        FOR p IN 1..4 LOOP
            INSERT INTO INTERFACE_RESEAU (nom, mac, debit_mbps, mtu, id_equipement)
            VALUES (
                'Gi0/' || p,
                mac_addr(1, 100000 + (i * 10) + p),
                1000,
                1500,
                v_equipements_cergy(i)
            )
            RETURNING id_interface INTO v_if_id;

            v_if_cergy_count := v_if_cergy_count + 1;
            v_interfaces_cergy(v_if_cergy_count) := v_if_id;

            INSERT INTO INTERFACE_RESEAU (nom, mac, debit_mbps, mtu, id_equipement)
            VALUES (
                'Gi0/' || p,
                mac_addr(2, 100000 + (i * 10) + p),
                1000,
                1500,
                v_equipements_pau(i)
            )
            RETURNING id_interface INTO v_if_id;

            v_if_pau_count := v_if_pau_count + 1;
            v_interfaces_pau(v_if_pau_count) := v_if_id;
        END LOOP;
    END LOOP;

    FOR i IN 1..v_if_cergy_count LOOP
        v_vlan_index := MOD(i - 1, 20) + 1;
        v_host := v_hosts_cergy(v_vlan_index);
        v_hosts_cergy(v_vlan_index) := v_host + 1;

        INSERT INTO ADRESSE_IP (adresse, version_ip, active, id_sous_reseau, id_interface)
        VALUES (
            '10.1.' || v_vlan_index || '.' || v_host,
            4,
            CASE WHEN MOD(i, 17) = 0 THEN '0' ELSE '1' END,
            v_sr_cergy(v_vlan_index),
            v_interfaces_cergy(i)
        );
    END LOOP;

    FOR i IN 1..v_if_pau_count LOOP
        v_vlan_index := MOD(i - 1, 20) + 1;
        v_host := v_hosts_pau(v_vlan_index);
        v_hosts_pau(v_vlan_index) := v_host + 1;

        INSERT INTO ADRESSE_IP (adresse, version_ip, active, id_sous_reseau, id_interface)
        VALUES (
            '10.2.' || v_vlan_index || '.' || v_host,
            4,
            CASE WHEN MOD(i, 19) = 0 THEN '0' ELSE '1' END,
            v_sr_pau(v_vlan_index),
            v_interfaces_pau(i)
        );
    END LOOP;

    FOR i IN 1..1000 LOOP
        INSERT INTO CONNEXION (
            id_interface_a,
            id_interface_b,
            type_connexion,
            active,
            date_creation
        )
        VALUES (
            v_interfaces_cergy((i * 2) - 1),
            v_interfaces_cergy(i * 2),
            'ETHERNET',
            CASE WHEN MOD(i, 13) = 0 THEN '0' ELSE '1' END,
            SYSDATE - MOD(i, 500)
        );

        INSERT INTO CONNEXION (
            id_interface_a,
            id_interface_b,
            type_connexion,
            active,
            date_creation
        )
        VALUES (
            v_interfaces_pau((i * 2) - 1),
            v_interfaces_pau(i * 2),
            'ETHERNET',
            CASE WHEN MOD(i, 11) = 0 THEN '0' ELSE '1' END,
            SYSDATE - MOD(i, 500)
        );
    END LOOP;

    FOR i IN 1..1000 LOOP
        INSERT INTO HISTO_AFFECTATION (
            id_materiel,
            id_user,
            id_site,
            date_debut,
            date_fin
        )
        VALUES (
            v_materiels_cergy(i),
            v_users_cergy(MOD(i - 1, 500) + 1),
            1,
            SYSDATE - 600 - MOD(i, 300),
            SYSDATE - 300 - MOD(i, 120)
        );

        INSERT INTO HISTO_AFFECTATION (
            id_materiel,
            id_user,
            id_site,
            date_debut,
            date_fin
        )
        VALUES (
            v_materiels_pau(i),
            v_users_pau(MOD(i - 1, 500) + 1),
            2,
            SYSDATE - 600 - MOD(i, 300),
            SYSDATE - 300 - MOD(i, 120)
        );
    END LOOP;

    COMMIT;
END;
/


-- 4. Rafraîchissement des vues matérialisées

BEGIN
    DBMS_MVIEW.REFRESH('MV_PARC_GLOBAL', 'C');
    DBMS_MVIEW.REFRESH('MV_TOPOLOGIE_GLOBAL', 'C');
END;
/


-- 5. Statistiques optimiseur

BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(
        ownname => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
    );
END;
/


-- 6. Volumétrie chargée

SELECT 'UTILISATEUR' AS objet, COUNT(*) AS nb_lignes FROM UTILISATEUR
UNION ALL
SELECT 'MATERIEL', COUNT(*) FROM MATERIEL
UNION ALL
SELECT 'INTERFACE_RESEAU', COUNT(*) FROM INTERFACE_RESEAU
UNION ALL
SELECT 'ADRESSE_IP', COUNT(*) FROM ADRESSE_IP
UNION ALL
SELECT 'CONNEXION', COUNT(*) FROM CONNEXION
UNION ALL
SELECT 'HISTO_AFFECTATION', COUNT(*) FROM HISTO_AFFECTATION;