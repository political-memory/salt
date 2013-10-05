git-django-representatives:
  git.latest:
    - name: https://github.com/yohanboniface/django-representatives.git
    - target: /home/bram/deploy/django-representatives
    - user: bram
    - runas: bram
    - require:
      - file: /home/bram/deploy
    - require_in:
      - cmd: compotista-syncdb
      - cmd: yolopol-syncdb
