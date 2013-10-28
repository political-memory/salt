postgresql:
  pkg.installed:
    - name: postgresql-9.1
  service.running:
    - require:
      - pkg: postgresql
