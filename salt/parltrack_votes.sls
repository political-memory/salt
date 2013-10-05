git-django-parltrack-votes:
  git.latest:
    - name: https://github.com/Psycojoker/django-parltrack-votes.git
    - target: /home/bram/deploy/django-parltrack-votes
    - user: bram
    - runas: bram
    - require:
      - file: /home/bram/deploy
    - require_in:
      - cmd: toutatis-syncdb
      - cmd: yolopol-syncdb
