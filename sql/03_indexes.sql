-- Objectif : création des index de performance


-- 1. INDEX SUR LES UTILISATEURS ET LES DROITS

-- Recherche rapide des utilisateurs actifs ou inactifs par site
CREATE INDEX idx_user_site_statut
ON UTILISATEUR(id_site, statut)
TABLESPACE TS_INDEX;


-- Recherche rapide des rôles attribués sur un site donné
CREATE INDEX idx_urs_site_role
ON USER_ROLE_SITE(id_site, id_role)
TABLESPACE TS_INDEX;


-- Recherche rapide des rôles d'un utilisateur
CREATE INDEX idx_urs_user
ON USER_ROLE_SITE(id_user)
TABLESPACE TS_INDEX;


-- 2. INDEX SUR LES LOCALISATIONS

-- Recherche des salles et bâtiments par site
CREATE INDEX idx_localisation_site_batiment_salle
ON LOCALISATION(id_site, batiment, salle)
TABLESPACE TS_INDEX;


-- 3. INDEX SUR LES MATERIELS

-- Index principal pour les requêtes de parc :
-- exemple : tous les ordinateurs actifs de Cergy
CREATE INDEX idx_materiel_site_type_statut
ON MATERIEL(id_site, type_materiel, statut)
TABLESPACE TS_INDEX;


-- Recherche du matériel affecté à un utilisateur responsable
CREATE INDEX idx_materiel_user_responsable
ON MATERIEL(id_user_responsable)
TABLESPACE TS_INDEX;


-- Recherche du matériel par localisation
CREATE INDEX idx_materiel_localisation
ON MATERIEL(id_localisation)
TABLESPACE TS_INDEX;


-- 4. INDEX SUR L'HISTORIQUE DES AFFECTATIONS

-- Historique des affectations d'un matériel
CREATE INDEX idx_histo_materiel_date
ON HISTO_AFFECTATION(id_materiel, date_debut)
TABLESPACE TS_INDEX;


-- Historique des matériels affectés à un utilisateur
CREATE INDEX idx_histo_user_date
ON HISTO_AFFECTATION(id_user, date_debut)
TABLESPACE TS_INDEX;


-- Historique par site
CREATE INDEX idx_histo_site_date
ON HISTO_AFFECTATION(id_site, date_debut)
TABLESPACE TS_INDEX;


-- 5. INDEX SUR LES EQUIPEMENTS RESEAU

-- Recherche des équipements réseau par site et par type
CREATE INDEX idx_equipement_site_type
ON EQUIPEMENT_RESEAU(id_site, type_equipement)
TABLESPACE TS_INDEX;


-- 6. INDEX SUR LES INTERFACES RESEAU

-- Recherche des interfaces rattachées à un matériel
CREATE INDEX idx_interface_materiel
ON INTERFACE_RESEAU(id_materiel)
TABLESPACE TS_INDEX;


-- Recherche des interfaces rattachées à un équipement réseau
CREATE INDEX idx_interface_equipement
ON INTERFACE_RESEAU(id_equipement)
TABLESPACE TS_INDEX;


-- 7. INDEX SUR LES VLAN ET SOUS-RESEAUX

-- Recherche des VLAN par site
CREATE INDEX idx_vlan_site
ON VLAN(id_site)
TABLESPACE TS_INDEX;


-- Recherche des sous-réseaux par site et VLAN
CREATE INDEX idx_sous_reseau_site_vlan
ON SOUS_RESEAU(id_site, id_vlan)
TABLESPACE TS_INDEX;


-- 8. INDEX SUR LES ADRESSES IP

-- Recherche rapide des adresses IP dans un sous-réseau
CREATE INDEX idx_ip_sous_reseau_adresse
ON ADRESSE_IP(id_sous_reseau, adresse)
TABLESPACE TS_INDEX;


-- Recherche des IP associées à une interface réseau
CREATE INDEX idx_ip_interface
ON ADRESSE_IP(id_interface)
TABLESPACE TS_INDEX;


-- Recherche des IP actives ou inactives
CREATE INDEX idx_ip_active
ON ADRESSE_IP(active)
TABLESPACE TS_INDEX;


-- 9. INDEX SUR LES CONNEXIONS RESEAU

-- Recherche des connexions actives depuis l'interface A
CREATE INDEX idx_connexion_interface_a_active
ON CONNEXION(id_interface_a, active)
TABLESPACE TS_INDEX;


-- Recherche des connexions actives depuis l'interface B
CREATE INDEX idx_connexion_interface_b_active
ON CONNEXION(id_interface_b, active)
TABLESPACE TS_INDEX;