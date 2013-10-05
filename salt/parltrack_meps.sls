git-parltrack-meps:
  git.latest:
    - name: https://github.com/Psycojoker/django-parltrack-meps.git
    - target: /home/bram/deploy/django-parltrack-meps
    - user: bram
    - runas: bram
    - require:
      - file: /home/bram/deploy
