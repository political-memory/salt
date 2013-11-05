include:
  - nginx
  - supervisor
  - parltrack_meps
  - deploy
  - virtualenv
  - cron
  - representatives
  - postgresql

{% for depot in ['compotista', 'django-parltrack-meps-to-representatives'] %}
git-{{ depot }}:
  git.latest:
    - name: https://github.com/Psycojoker/{{ depot }}.git
    - target: /home/bram/deploy/{{ depot }}
    - user: bram
    - runas: bram
    - require:
      - file: /home/bram/deploy
    - require_in:
      - cmd: compotista-syncdb

{% if depot != 'compotista' %}
/home/bram/deploy/compotista/{{ depot|replace('django-', '')|replace('-', '_') }}:
  file.symlink:
    - target: /home/bram/deploy/{{ depot }}/{{ depot|replace('django-', '')|replace('-', '_')}}
    - user: bram
    - group: bram
    - require:
      - git: git-compotista
      - git: git-{{ depot }}
    - require_in:
      - cmd: compotista-syncdb
{% endif %}
{% endfor %}

/home/bram/deploy/compotista/parltrack_meps:
  file.symlink:
    - target: /home/bram/deploy/django-parltrack-meps/parltrack_meps
    - user: bram
    - group: bram
    - require:
      - git: git-compotista
      - git: git-django-parltrack-votes
    - require_in:
      - cmd: compotista-syncdb

/home/bram/deploy/compotista/representatives:
  file.symlink:
    - target: /home/bram/deploy/django-representatives/representatives
    - user: bram
    - group: bram
    - require:
      - git: git-compotista
      - git: git-django-representatives
    - require_in:
      - cmd: compotista-syncdb

/home/bram/deploy/compotista/ve:
  file.directory:
    - user: bram
    - group: bram
    - makedirs: True
    - require:
      - git: git-compotista
  virtualenv.managed:
    - requirements: /home/bram/deploy/compotista/requirements.txt
    - runas: bram
    - require:
      - git: git-compotista
      - file: /home/bram/deploy/compotista/ve
      - pkg: python-virtualenv

compotista-syncdb:
  cmd.wait:
    - name: ve/bin/python manage.py syncdb --noinput
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/compotista/
    - require:
      - virtualenv: /home/bram/deploy/compotista/ve
      - git: git-parltrack-meps
      - postgres_database: compotista
    - watch_in:
      - cmd: compotista-update_meps

compotista-update_meps:
  cmd.wait:
    - name: ve/bin/python manage.py update_meps
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/compotista

compotista-cron:
  cron.present:
    - name: cd /home/bram/deploy/compotista/ && ve/bin/python manage.py update_meps && ve/bin/python manage.py convert_meps_to_representatives && ve/bin/python manage.py create_an_export
    - user: bram
    - minute: 42
    - hour: 2
    - require:
      - cmd: compotista-syncdb
      - pkg: cron

compotista-additionnal-pkgs:
  pkg.installed:
    - names:
      - postgresql-server-dev-9.1
      - python-dev
    - require_in:
      - pip: compotista-additional-pip-pkgs

compotista-additional-pip-pkgs:
  pip.installed:
    - names:
      - ipython
      - debug
      - gunicorn
      - psycopg2
    - user: bram
    - bin_env: /home/bram/deploy/compotista/ve/bin/pip
    - require:
      - virtualenv: /home/bram/deploy/compotista/ve

compotista_settings_local:
  file.managed:
    - name: /home/bram/deploy/compotista/compotista/settings_local.py
    - source: salt://compotista/settings_local.py
    - user: bram
    - group: bram
    - watch_in:
      - cmd: compotista-syncdb
      - cmd: compotista-restart
    - require:
      - git: git-compotista

compotista:
  postgres_database.present:
    - runas: bram
    - user: bram
    - watch_in:
      - cmd: compotista-syncdb

compotista-restart:
  cmd.wait:
    - name: supervisorctl restart compotista
    - require:
      - file: /etc/supervisor/conf.d/compotista.conf

/etc/supervisor/conf.d/compotista.conf:
  file.managed:
    - source: salt://compotista/supervisor.conf
    - makedirs: true
    - watch_in:
      - cmd: supervisor-update
    - require:
      - service: postgresql
      - file: compotista_settings_local
      - postgres_database: compotista

/etc/nginx/sites-available/compotista.conf:
  file.managed:
    - source: salt://nginx/template.conf
    - template: jinja
    - context:
        static: False
        name: compotista
        port: 7910
    - require:
      - pkg: nginx

/etc/nginx/sites-enabled/compotista.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/compotista.conf
    - require:
      - file: /etc/nginx/sites-available/compotista.conf
    - watch_in:
      - cmd: nginx-reload
