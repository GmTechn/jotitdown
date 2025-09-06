---

# 📌 Projet Final : **Application Jot It Down**

🔗 **Lien GitHub** : [https://github.com/GmTechn/jotitdown](https://github.com/GmTechn/jotitdown)

---

## 📖 Description

**Jot It Down** est une application simple et intuitive qui aide les utilisateurs à gérer leurs tâches quotidiennes.
Elle permet de suivre facilement les tâches en retard, en cours et à venir.

---

## 📱 Fonctionnalités principales

### 1. **Login**

* Permet aux utilisateurs ayant déjà un compte de se connecter.

---

### 2. **Sign Up (Créer un compte)**

* Permet la création d’un nouveau compte utilisateur.

---

### 3. **Dashboard**

Donne un récapitulatif de l’état actuel des tâches.
Il comprend :

* Un bouton vers le **profil** avec le nom de l’utilisateur.
* Une **cloche de notification** qui redirige vers les tâches en retard (*overdue*).
* Le **nombre total de notes/tâches** enregistrées et le **nombre total de tâches accomplies** pour la journée.
* Un **mot d’encouragement**, rappelant le nombre de tâches accomplies dans la journée.
* Une section listant les tâches :

  * **Overdues (en retard)**
  * **En cours**
  * **À venir** (selon les heures définies dans *Schedule*)

---

### 4. **Tasks**

Page qui permet d’enregistrer une tâche avec son statut et sa date.

* Ajout d’une nouvelle tâche via le bouton **+**.
* Informations à renseigner :

  * Statut (*To do → À faire, In progress → En cours, Done → Accomplie*)
  * Titre et sous-titre
  * Date

➡️ Lors de la création de plusieurs tâches, elles apparaissent sur cette page avec un **code couleur selon le statut** :

* 🔴 Rouge : *To do*

* 🟠 Orange : *In progress*

* 🟢 Vert : *Done*

* Les **filtres** permettent d’afficher uniquement les tâches correspondant à chaque statut.

---

### 5. **Schedule**

Liste toutes les tâches en fonction des jours.

Fonctionnalités :

* Définir une **heure de début et de fin** pour chaque tâche (via l’icône horloge).
* Affichage des tâches avec un code couleur :

  * 🔴 Rouge : *Overdue*
  * 🟠 Orange : *En cours* (au moment de la tâche)
  * 🟢 Vert : *Done*
  * ⚪ Gris : Tâche prévue plus tard dans la journée
* Navigation entre les différents jours grâce aux **filtres** en haut de la page.

---

### 6. **Profile**

Permet de gérer les informations personnelles de l’utilisateur :

* Changement de photo de profil
* Modification des informations personnelles

  * **Update** : mettre à jour
  * **Cancel** : annuler les changements
* **Logout** (tout en haut) : déconnexion

---

### 7. **Forgot Password** (non implémenté)

Prévu pour permettre à l’utilisateur de recréer un mot de passe via son email (en recevant un lien).

---

## 📚 Ressources utilisées

* **Wireframe & Inspiration :**
  [Dribbble – Note App UX/UI Design](https://dribbble.com/shots/24116561-Note-App-UXUI-Design)

* **Code de la barre de navigation :**
  [FlutterBricks](https://www.flutterbricks.com/preview)

* **Création de ListTiles, logique des filtres & gestion des heures :**

  * ChatGPT
  * Développeur Flutter **Mitch Koko**

    * [Chaîne YouTube](https://www.youtube.com/@createdbykoko)

---
