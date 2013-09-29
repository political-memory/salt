{% for user, depot in [('Psycojoker', 'compotista'), ('Psycojoker', 'django-parltrack-meps'), ('Psycojoker', 'django-parltrack-meps-to-representatives'), ('yohanboniface', 'django-representatives')] %}
git-{{ depot }}:
  git.latest:
    - name: https://github.com/{{ user }}/{{ depot }}.git
    - target: /home/bram/deploy/{{ depot }}
    - user: bram
    - require:
      - file: /home/bram/deploy

{% if depot != 'compotista' %}
/home/bram/deploy/compotista/{{ depot|replace('django-', '')|replace('-', '_') }}:
  file.symlink:
    - target: /home/bram/deploy/compotista/{{ depot|replace('django-', '')|replace('-', '_')}}
    - user: bram
    - group: bram
    - require:
      - git: git-compotista
      - git: git-{{ depot }}
{% endif %}
{% endfor %}

/home/bram/deploy:
  file.directory:
    - user: bram
    - group: bram
    - makedirs: True
