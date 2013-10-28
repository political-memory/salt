postgresql:
  pkg.installed:
    - name: postgresql-9.1
    - watch_in:
      - postgres_user: bram
  service.running:
    - require:
      - pkg: postgresql

bram:
  postgres_user.present:
    - superuser: True
    - require:
      - service: postgresql
