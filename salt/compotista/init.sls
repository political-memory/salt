{% for user, depot in [('Psycojoker', 'compotista'), ('Psycojoker', 'django-parltrack-meps'), ('Psycojoker', 'django-parltrack-meps-to-representatives'), ('yohanboniface', 'django-representatives')] %}
git-{{ depot }}:
  git.latest:
    - name: https://github.com/{{ user }}/{{ depot }}.git
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

/home/bram/deploy:
  file.directory:
    - user: bram
    - group: bram
    - makedirs: True

python-virtualenv:
  pkg.installed

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

cron:
  pkg.installed
