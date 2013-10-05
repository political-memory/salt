include:
  - nginx
  - supervisor
  - parltrack_meps
  - deploy
  - virtualenv
  - cron
  - parltrack_votes

git-toutatis:
  git.latest:
    - name: https://github.com/Psycojoker/toutatis.git
    - target: /home/bram/deploy/toutatis
    - user: bram
    - runas: bram
    - require:
      - file: /home/bram/deploy
    - require_in:
      - cmd: toutatis-syncdb

/home/bram/deploy/toutatis/parltrack_votes:
  file.symlink:
    - target: /home/bram/deploy/django-parltrack-votes/parltrack_votes
    - user: bram
    - group: bram
    - require:
      - git: git-toutatis
      - git: git-django-parltrack-votes
    - require_in:
      - cmd: toutatis-syncdb

/home/bram/deploy/toutatis/parltrack_meps:
  file.symlink:
    - target: /home/bram/deploy/django-parltrack-meps/parltrack_meps
    - user: bram
    - group: bram
    - require:
      - git: git-toutatis
      - git: git-django-parltrack-votes
    - require_in:
      - cmd: toutatis-syncdb

/home/bram/deploy/toutatis/ve:
  file.directory:
    - user: bram
    - group: bram
    - makedirs: True
  virtualenv.managed:
    - requirements: /home/bram/deploy/toutatis/requirements.txt
    - runas: bram
    - require:
      - git: git-toutatis
      - file: /home/bram/deploy/toutatis/ve
      - pkg: python-virtualenv

toutatis-syncdb:
  cmd.run:
    - name: ve/bin/python manage.py syncdb --noinput
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/toutatis
    - unless: ls db.sqlite
    - require:
      - virtualenv: /home/bram/deploy/toutatis/ve
      - git: git-parltrack-meps
    - watch_in:
      - cmd: toutatis-update_meps

toutatis-update_meps:
  cmd.wait:
    - name: ve/bin/python manage.py update_meps
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/toutatis

toutatis-cron:
  cron.present:
    - name: cd /home/bram/deploy/toutatis/ && ve/bin/python manage.py update_meps
    - user: bram
    - minute: 42
    - hour: 2
    - require:
      - cmd: toutatis-syncdb
      - pkg: cron

toutatis-additional-pip-pkgs:
  pip.installed:
    - names:
      - ipython
      - debug
      - gunicorn
    - user: bram
    - bin_env: /home/bram/deploy/toutatis/ve/bin/pip
    - require:
      - virtualenv: /home/bram/deploy/toutatis/ve

{#
/etc/supervisor/conf.d/toutatis.conf:
  file.managed:
    - source: salt://toutatis/supervisor.conf
    - makedirs: true
    - watch_in:
      - cmd: supervisor-update
#}
