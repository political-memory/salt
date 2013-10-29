nginx:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: nginx

nginx-reload:
  cmd.wait:
    - name: service nginx reload
