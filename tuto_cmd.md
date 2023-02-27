### ouverture d'un terminal

```sh
ctrl + alt + t
```

### déplacements de base dans l'arborescence des fichiers
```sh 
cd /un/chemin/vers/un/dossier       # pour se déplacer daans l'arborescence
cd ..         # pour remonter d'un dossier
cd            # pour revenir au "point de base" du terminal (~/home/reds/)
```

### manipulation de base pour les fichiers 
```sh
touch mon_fichier.mon_extension     # pour créer un fichier
rm mon_fichier                      # pour supprimer un fichier
mkdir mon_répertoire                # pour créer un répertoire
rm -r mon_répertoire                # pour effacer un répertoire et son contenu
```

### se rendre dans votre dossier du labo pour le vhdl
```sh
csf         # à mettre en place pour kristina
cd csf_lab01/lab01/votre_prénom/code/hard/src_vhdl/ 
``` 

### se rendre dans le dossier pour lancer le testbench
```sh
csf 
cd csf_lab01/lab01/basile/code/hard/
mkdir sim # à faire seulement la première fois 
cd sim
vsim
``` 

### lancer la simulation dans vsim (questasim)
Dans le terminal de vsim:
```sh
do ../scripts/sim.do <kristina|jeremy> <numéro du test case> #numéro du test case: 0 pour tout, 1 pour read write simples, 2 pour tests du compteur
```

### utilisation de git (il vaut mieux être dans le répertoire csf_lab01 pour ces commandes)
```sh
git pull        # Toujours à faire avant toutes les autres commandes git, pour récupérer les mises à jour depuis git, si problème de conflit, me demander. 
git status      # affiche en rouge ce qui ne sera pas ajouté lors d'un push et en vert ce qui le sera
git add un_fichier_en_rouge     # ajoute un fichier qui était en rouge dans le git status dans la liste à envoyer sur git (pas hésiter à refaire des git status pour voir la progression)
git reset                       # si vous vous êtes foirés dans ce que vous avez ajouté à la liste à push
git commit -m "un message pour expliquer ce qu'on a fait"   # crée ce qu'il faut pour pouvoir envoyer les modifs sur git
git push        # envoie les modifications sur git
```



