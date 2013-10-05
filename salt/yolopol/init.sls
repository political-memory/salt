include:
  - nginx
  - supervisor
  - deploy
  - virtualenv
  - representatives
  - parltrack_votes

git-yolopol:
  git.latest:
    - name: https://github.com/Psycojoker/yolopol.git
    - target: /home/bram/deploy/yolopol
    - user: bram
    - runas: bram
    - require:
      - file: /home/bram/deploy
    - require_in:
      - cmd: yolopol-syncdb
    - watch_in:
      - cmd: yolopol-syncdb

/home/bram/deploy/yolopol/parltrack_votes:
  file.symlink:
    - target: /home/bram/deploy/django-parltrack-votes/parltrack_votes
    - user: bram
    - group: bram
    - require:
      - git: git-yolopol
      - git: git-django-parltrack-votes
    - require_in:
      - cmd: yolopol-syncdb

/home/bram/deploy/yolopol/representatives:
  file.symlink:
    - target: /home/bram/deploy/django-representatives/representatives
    - user: bram
    - group: bram
    - require:
      - git: git-yolopol
      - git: git-django-representatives
    - require_in:
      - cmd: yolopol-syncdb

/home/bram/deploy/yolopol/ve:
  file.directory:
    - user: bram
    - group: bram
    - makedirs: True
  virtualenv.managed:
    - requirements: /home/bram/deploy/yolopol/requirements.txt
    - runas: bram
    - require:
      - git: git-yolopol
      - file: /home/bram/deploy/yolopol/ve
      - pkg: python-virtualenv

yolopol-syncdb:
  cmd.run:
    - name: ve/bin/python manage.py syncdb --noinput
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/yolopol
    - unless: ls db.sqlite
    - require:
      - virtualenv: /home/bram/deploy/yolopol/ve
      - git: git-yolopol
    - watch_in:
      - cmd: yolopol-migrate-db

yolopol-migrate-db:
  cmd.wait:
    - name: ve/bin/python manage.py syncdb --noinput
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/yolopol
    - require:
      - virtualenv: /home/bram/deploy/yolopol/ve
      - git: git-yolopol

yolopol-additional-pip-pkgs:
  pip.installed:
    - names:
      - ipython
      - debug
      - gunicorn
    - user: bram
    - bin_env: /home/bram/deploy/yolopol/ve/bin/pip
    - require:
      - virtualenv: /home/bram/deploy/yolopol/ve

{#
/etc/supervisor/conf.d/yolopol.conf:
  file.managed:
    - source: salt://yolopol/supervisor.conf
    - makedirs: true
    - watch_in:
      - cmd: supervisor-update
#}
