-- =============================================================================
-- Nom du fichier : 07_test_data.sql
-- Projet : TAD - Refonte BDD GLPI (CY Tech)
-- Objectif : Génération d'un jeu de données massif pour tests de performance
-- =============================================================================

SET SERVEROUTPUT ON;
SET FEEDBACK OFF;

PROMPT Initialisation du remplissage des données...

-- 1. NETTOYAGE PRÉALABLE (Optionnel si tu n'utilises pas 00_reset.sql)
-- DELETE FROM CONNEXION_RESEAU;
-- DELETE FROM INTERFACE_RESEAU;
-- DELETE FROM ADRESSE_IP;
-- DELETE FROM MATERIEL;
-- DELETE FROM UTILISATEUR;
-- DELETE FROM VLAN;
-- DELETE FROM SITE;
-- COMMIT;

-- 2. DONNÉES DE RÉFÉRENCE (Statiques)
PROMPT Insertion des sites et types...
INSERT INTO SITE (id_site, nom_site, ville) VALUES (1, 'CY Cergy - Parc des Portes', 'Cergy');
INSERT INTO SITE (id_site, nom_site, ville) VALUES (2, 'CY Pau - Technopôle Helios', 'Pau');

INSERT INTO ROLE (id_role, libelle) VALUES (1, 'Administrateur');
INSERT INTO ROLE (id_role, libelle) VALUES (2, 'Technicien');
INSERT INTO ROLE (id_role, libelle) VALUES (3, 'Utilisateur Standard');
INSERT INTO ROLE (id_role, libelle) VALUES (4, 'Invité');

INSERT INTO TYPE_MATERIEL (id_type, libelle) VALUES (1, 'Ordinateur Portable');
INSERT INTO TYPE_MATERIEL (id_type, libelle) VALUES (2, 'Serveur');
INSERT INTO TYPE_MATERIEL (id_type, libelle) VALUES (3, 'Switch Réseau');
INSERT INTO TYPE_MATERIEL (id_type, libelle) VALUES (4, 'Borne Wi-Fi');
COMMIT;

-- 3. GÉNÉRATION DES VLANs (Spécifiques par site)
PROMPT Génération des VLANs...
BEGIN
    FOR v IN 1..10 LOOP
        INSERT INTO VLAN (id_vlan, nom_vlan, id_site) 
        VALUES (v, 'VLAN_DEPT_' || v, CASE WHEN v <= 5 THEN 1 ELSE 2 END);
    END LOOP;
    COMMIT;
END;
/

-- 4. GÉNÉRATION DES UTILISATEURS (500 lignes)
-- On utilise MOD(i, 2) pour répartir 50% à Cergy et 50% à Pau
PROMPT Génération de 500 utilisateurs...
BEGIN
    FOR i IN 1..500 LOOP
        INSERT INTO UTILISATEUR (id_user, nom, prenom, id_role, id_site, email)
        VALUES (
            i, 
            'NOM_' || i, 
            'PRENOM_' || i, 
            DBMS_RANDOM.VALUE(1, 4), 
            CASE WHEN MOD(i, 2) = 0 THEN 1 ELSE 2 END,
            'user' || i || '@cy-tech.fr'
        );
    END LOOP;
    COMMIT;
END;
/

-- 5. GÉNÉRATION DU MATÉRIEL (3000 lignes)
-- Indispensable pour tester les INDEX et CLUSTERS
PROMPT Génération de 3000 matériels informatiques...
BEGIN
    FOR i IN 1..3000 LOOP
        INSERT INTO MATERIEL (id_mat, num_serie, id_type, id_site, id_user, statut, date_achat)
        VALUES (
            i,
            'SN-' || DBMS_RANDOM.STRING('X', 12),
            DBMS_RANDOM.VALUE(1, 4),
            CASE WHEN MOD(i, 2) = 0 THEN 1 ELSE 2 END,
            DBMS_RANDOM.VALUE(1, 500), -- Affectation aléatoire à un utilisateur
            CASE WHEN MOD(i, 10) = 0 THEN 'MAINTENANCE' ELSE 'EN_SERVICE' END,
            SYSDATE - DBMS_RANDOM.VALUE(1, 1500)
        );
        -- Commit intermédiaire pour la performance
        IF MOD(i, 500) = 0 THEN COMMIT; END IF;
    END LOOP;
    COMMIT;
END;
/

-- 6. GÉNÉRATION DU RÉSEAU (1000 Adresses IP)
PROMPT Génération des adresses IP et interfaces...
BEGIN
    FOR i IN 1..1000 LOOP
        -- Simulation d'IP : 192.168.[VLAN].[1-254]
        INSERT INTO ADRESSE_IP (id_ip, adresse, id_vlan, statut)
        VALUES (
            i, 
            '192.168.' || (MOD(i, 10) + 1) || '.' || (MOD(i, 250) + 1),
            MOD(i, 10) + 1,
            'ATTRIBUEE'
        );
        
        -- On lie l'IP au matériel (1 IP par matériel pour les 1000 premiers)
        INSERT INTO INTERFACE_RESEAU (id_interface, mac_adresse, id_mat, id_ip)
        VALUES (
            i,
            '00:1A:2B:' || DBMS_RANDOM.STRING('X', 2) || ':' || DBMS_RANDOM.STRING('X', 2) || ':' || DBMS_RANDOM.STRING('X', 2),
            i,
            i
        );
    END LOOP;
    COMMIT;
END;
/

PROMPT Remplissage terminé avec succès !
PROMPT Statistiques du jeu de données :
SELECT 'Utilisateurs' as Table, COUNT(*) FROM UTILISATEUR
UNION ALL
SELECT 'Matériels', COUNT(*) FROM MATERIEL
UNION ALL
SELECT 'Adresses IP', COUNT(*) FROM ADRESSE_IP;

SET FEEDBACK ON;