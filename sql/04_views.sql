-- ============================================================
-- Mini-projet GLPI CY Tech
-- Fichier : 04_views.sql
-- Objectif : création des vues métier pour simplifier les requêtes
-- ============================================================


-- ============================================================
-- 1. Vue du parc matériel par site
-- ============================================================
-- Cette vue permet de consulter rapidement le parc informatique
-- avec le site, le responsable et la localisation du matériel.

CREATE OR REPLACE VIEW V_PARC_SITE AS
SELECT
    s.id_site,
    s.code_site,
    s.nom AS nom_site,
    s.ville,
    m.id_materiel,
    m.inventaire,
    m.nom AS nom_materiel,
    m.type_materiel,
    m.statut AS statut_materiel,
    u.id_user AS id_responsable,
    u.nom AS nom_responsable,
    u.prenom AS prenom_responsable,
    l.batiment,
    l.salle,
    m.date_creation,
    m.date_modification
FROM MATERIEL m
JOIN SITE s
    ON m.id_site = s.id_site
LEFT JOIN UTILISATEUR u
    ON m.id_user_responsable = u.id_user
LEFT JOIN LOCALISATION l
    ON m.id_localisation = l.id_localisation;


-- ============================================================
-- 2. Vue des utilisateurs et de leurs rôles par site
-- ============================================================
-- Cette vue permet de voir les droits métier affectés
-- aux utilisateurs selon leur site.

CREATE OR REPLACE VIEW V_UTILISATEURS_ROLES_SITE AS
SELECT
    s.code_site,
    s.nom AS nom_site,
    u.id_user,
    u.login,
    u.nom,
    u.prenom,
    u.email,
    u.statut,
    r.code_role,
    r.libelle AS libelle_role,
    urs.date_debut,
    urs.date_fin
FROM USER_ROLE_SITE urs
JOIN UTILISATEUR u
    ON urs.id_user = u.id_user
JOIN ROLE r
    ON urs.id_role = r.id_role
JOIN SITE s
    ON urs.id_site = s.id_site;


-- ============================================================
-- 3. Vue de l'historique des affectations
-- ============================================================
-- Cette vue permet de suivre les changements d'affectation
-- des matériels aux utilisateurs.

CREATE OR REPLACE VIEW V_HISTO_AFFECTATIONS AS
SELECT
    h.id_histo,
    s.code_site,
    s.nom AS nom_site,
    m.id_materiel,
    m.inventaire,
    m.nom AS nom_materiel,
    m.type_materiel,
    u.id_user,
    u.nom AS nom_utilisateur,
    u.prenom AS prenom_utilisateur,
    h.date_debut,
    h.date_fin
FROM HISTO_AFFECTATION h
JOIN MATERIEL m
    ON h.id_materiel = m.id_materiel
LEFT JOIN UTILISATEUR u
    ON h.id_user = u.id_user
JOIN SITE s
    ON h.id_site = s.id_site;


-- ============================================================
-- 4. Vue de la topologie réseau
-- ============================================================
-- Cette vue donne une vision synthétique des interfaces,
-- équipements réseau, VLAN, sous-réseaux et adresses IP.

CREATE OR REPLACE VIEW V_TOPOLOGIE_RESEAU AS
SELECT
    s.id_site,
    s.code_site,
    s.nom AS nom_site,
    er.id_equipement,
    er.nom AS nom_equipement,
    er.type_equipement,
    er.ip_mgmt,
    ir.id_interface,
    ir.nom AS nom_interface,
    ir.mac,
    ir.debit_mbps,
    ir.mtu,
    v.numero_vlan,
    v.nom AS nom_vlan,
    sr.cidr,
    sr.passerelle,
    ip.adresse,
    ip.version_ip,
    ip.active AS ip_active
FROM SITE s
JOIN EQUIPEMENT_RESEAU er
    ON er.id_site = s.id_site
JOIN INTERFACE_RESEAU ir
    ON ir.id_equipement = er.id_equipement
LEFT JOIN ADRESSE_IP ip
    ON ip.id_interface = ir.id_interface
LEFT JOIN SOUS_RESEAU sr
    ON ip.id_sous_reseau = sr.id_sous_reseau
LEFT JOIN VLAN v
    ON sr.id_vlan = v.id_vlan;


-- ============================================================
-- 5. Vue des interfaces des matériels
-- ============================================================
-- Cette vue complète la vue réseau en affichant les interfaces
-- rattachées aux matériels utilisateurs.

CREATE OR REPLACE VIEW V_INTERFACES_MATERIELS AS
SELECT
    s.code_site,
    s.nom AS nom_site,
    m.id_materiel,
    m.inventaire,
    m.nom AS nom_materiel,
    m.type_materiel,
    ir.id_interface,
    ir.nom AS nom_interface,
    ir.mac,
    ir.debit_mbps,
    ir.mtu,
    ip.adresse,
    ip.version_ip,
    ip.active AS ip_active
FROM MATERIEL m
JOIN SITE s
    ON m.id_site = s.id_site
JOIN INTERFACE_RESEAU ir
    ON ir.id_materiel = m.id_materiel
LEFT JOIN ADRESSE_IP ip
    ON ip.id_interface = ir.id_interface;


-- ============================================================
-- 6. Vue des connexions réseau actives
-- ============================================================
-- Cette vue permet de reconstituer les liaisons entre interfaces.

CREATE OR REPLACE VIEW V_CONNEXIONS_ACTIVES AS
SELECT
    c.id_connexion,
    c.type_connexion,
    c.date_creation,
    ia.id_interface AS id_interface_a,
    ia.nom AS interface_a,
    ia.mac AS mac_a,
    ib.id_interface AS id_interface_b,
    ib.nom AS interface_b,
    ib.mac AS mac_b
FROM CONNEXION c
JOIN INTERFACE_RESEAU ia
    ON c.id_interface_a = ia.id_interface
JOIN INTERFACE_RESEAU ib
    ON c.id_interface_b = ib.id_interface
WHERE c.active = '1';


-- ============================================================
-- 7. Vue des adresses IP par site
-- ============================================================
-- Cette vue permet d'identifier rapidement les IP utilisées
-- sur chaque site, notamment pour détecter les conflits.

CREATE OR REPLACE VIEW V_IP_PAR_SITE AS
SELECT
    s.code_site,
    s.nom AS nom_site,
    sr.cidr,
    v.numero_vlan,
    v.nom AS nom_vlan,
    ip.adresse,
    ip.version_ip,
    ip.active,
    ir.nom AS nom_interface,
    ir.mac
FROM ADRESSE_IP ip
JOIN SOUS_RESEAU sr
    ON ip.id_sous_reseau = sr.id_sous_reseau
JOIN SITE s
    ON sr.id_site = s.id_site
LEFT JOIN VLAN v
    ON sr.id_vlan = v.id_vlan
LEFT JOIN INTERFACE_RESEAU ir
    ON ip.id_interface = ir.id_interface;


-- ============================================================
-- 8. Vue globale du parc CY Tech
-- ============================================================
-- Cette vue sert de base à une vision consolidée Cergy + Pau.
-- Elle sera aussi utile pour la partie BDDR.

CREATE OR REPLACE VIEW V_PARC_GLOBAL AS
SELECT
    code_site,
    nom_site,
    ville,
    id_materiel,
    inventaire,
    nom_materiel,
    type_materiel,
    statut_materiel,
    nom_responsable,
    prenom_responsable,
    batiment,
    salle
FROM V_PARC_SITE;