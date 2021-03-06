supervisor:
  pkg:
    - installed
  service:
    - running

supervisor-update:
  cmd.wait:
    - name: supervisorctl update
    - require:
      - pkg: supervisor
      - service: supervisor
