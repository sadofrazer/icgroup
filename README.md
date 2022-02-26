# _PROJET FIL ROUGE IC WEBAPP DE IC GROUP_

Il s'agit à ce stade de mettre en place notre pipeline CI/CD à l'aide de l'outil Jenkins.


  Ce pipeline dans cette première version devra permettre de builder notre Dockerfile, tester l'image et sauvegarder la nouvelle release sur le Dockehub.
Toutefois la version à utiliser pour la sauvegarde de l'image devra etre dynamiquement récupérée lors de l'exécution de notre Pipeline dans le fichier releases.txt de notre repo.


  Après avoir terminé avec la partie CI de notre pipeline, nous devrons passer à la prtie CD qui consistera à déployer notre site vitrine dans les environnement de staging et de Prod. le déploiement du site vitrine devra prendre en compte la valeur de la variable `deploy_app` se trouvant également dans le fichier releases.txt.


  En effet cette variable permettra de décider si nous devrons au cours du pipeline déployer également de nouvelles instances pour les applications metiers de IC GROUP (Odoo et Postgres). Si deploy_app = yes, alors on devra non seulement déployer les applications Odoo et Pgadmin et les rendre disponibles à partir de notre site vitrine. par contre si deploy_app = no, nous devrons juste déployer le site vitrine et utiliser les URL ODOO_URL et PGADMIN_URL se trouvant également dans le fichier releases.txt.
