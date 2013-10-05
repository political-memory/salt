include:
  - nginx
  - supervisor
  - parltrack_meps
  - deploy
  - virtualenv
  - cron
  - representatives

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
  virtualenv.managed:
    - requirements: /home/bram/deploy/compotista/requirements.txt
    - runas: bram
    - require:
      - git: git-compotista
      - file: /home/bram/deploy/compotista/ve
      - pkg: python-virtualenv

compotista-syncdb:
  cmd.run:
    - name: ve/bin/python manage.py syncdb --noinput
    - user: bram
    - group: bram
    - cwd: /home/bram/deploy/compotista
    - unless: ls db.sqlite
    - require:
      - virtualenv: /home/bram/deploy/compotista/ve
      - git: git-parltrack-meps
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

compotista-additional-pip-pkgs:
  pip.installed:
    - names:
      - ipython
      - debug
      - gunicorn
    - user: bram
    - bin_env: /home/bram/deploy/compotista/ve/bin/pip
    - require:
      - virtualenv: /home/bram/deploy/compotista/ve

/etc/supervisor/conf.d/compotista.conf:
  file.managed:
    - source: salt://compotista/supervisor.conf
    - makedirs: true
    - watch_in:
      - cmd: supervisor-update
