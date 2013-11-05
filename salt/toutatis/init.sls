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
    - watch_in:
      - cmd: toutatis-restart

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
  cmd.wait:
    - name: ve/bin/python manage.py syncdb --noinput
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/toutatis
    - require:
      - virtualenv: /home/bram/deploy/toutatis/ve
      - git: git-parltrack-meps
      - pip: toutatis-additional-pip-pkgs

toutatis-update_meps:
  cmd.wait:
    - name: ve/bin/python manage.py update_meps
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/toutatis

toutatis-import_ep_votes_data:
  cmd.wait:
    - name: ve/bin/python manage.py import_ep_votes_data
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/toutatis

toutatis-cron:
  cron.present:
    - name: cd /home/bram/deploy/toutatis/ && ve/bin/python manage.py update_meps && ve/bin/python manage.py import_ep_votes_data
    - user: bram
    - minute: 42
    - hour: 2
    - require:
      - cmd: toutatis-syncdb
      - pkg: cron

toutatis-additionnal-pkgs:
  pkg.installed:
    - names:
      - postgresql-server-dev-9.1
      - python-dev
    - require_in:
      - pip: toutatis-additional-pip-pkgs

toutatis-additional-pip-pkgs:
  pip.installed:
    - names:
      - ipython
      - debug
      - gunicorn
      - psycopg2
    - user: bram
    - bin_env: /home/bram/deploy/toutatis/ve/bin/pip
    - require:
      - virtualenv: /home/bram/deploy/toutatis/ve

toutatis_settings_local:
  file.managed:
    - name: /home/bram/deploy/toutatis/toutatis/settings_local.py
    - source: salt://toutatis/settings_local.py
    - user: bram
    - group: bram
    - watch_in:
      - cmd: toutatis-syncdb
      #- cmd: restart-toutatis
    - require:
      - git: git-toutatis

toutatis:
  postgres_database.present:
    - runas: bram
    - user: bram
    - watch_in:
      - cmd: toutatis-syncdb
      - cmd: toutatis-update_meps
      - cmd: toutatis-import_ep_votes_data

/etc/supervisor/conf.d/toutatis.conf:
  file.managed:
    - source: salt://toutatis/supervisor.conf
    - makedirs: true
    - require:
      - service: supervisor
      - postgres_database: toutatis
    - watch_in:
      - cmd: supervisor-update

toutatis-restart:
  cmd.wait:
    - name: supervisorctl restart toutatis
    - require:
      - file: /etc/supervisor/conf.d/toutatis.conf

/etc/nginx/sites-available/toutatis.conf:
  file.managed:
    - source: salt://nginx/template.conf
    - template: jinja
    - context:
        static: False
        name: toutatis
        port: 1110
    - require:
      - pkg: nginx

/etc/nginx/sites-enabled/toutatis.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/toutatis.conf
    - require:
      - file: /etc/nginx/sites-available/toutatis.conf
    - watch_in:
      - cmd: nginx-reload
