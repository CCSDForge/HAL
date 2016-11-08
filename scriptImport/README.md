# Scripts
Poser ici tous les scripts utilisés pour faire des imports par lot
Pour chaque script, ajouter un paragraphe pour décrire le script

Bib2HAL_git.js
* Prérequis : Disposer de l'application Zotero (www.zotero.org) sur votre ordinateur. Installer le script dans le répertoire Translators de votre profil Zotero
* Usage : Sélectionner les références à exporter dans Zotero, puis cliquer-droit sur Exporter les documents et choisir le format Bib2HAL
* Description du traitement : le script met en forme un fichier bibtex en sortie répondant au prérequis de l'outil BIB2HAL : 
* Sortie : fichier bibtex

ImportParLotSword.php
* Prérequis : Avoir un fichier TEI avec 1 ou plusieurs documents, un document par bibFull + Créer un sous répertoire : xmlSword dans le lequel seront copiés tous les xml utilisés pour l'import Sword
* Usage : php ImportParLotSword.php -f=fichier_tei.xml -u=HALLogin -p=HALPassword
* Description du traitement : Ce script prend en entrée un fichier xml au format TEI-HAL, découpe la TEI en un fichier par biblFull, copie le fichier dans xmlSword et lance l'import Sword
* Sortie : Pour chaque document, on a l'id de la publication dans HAL et le mot de passe, un lien vers le document dans HAL.
En cas d'erreur Sword, le message d'erreur est affiché.
