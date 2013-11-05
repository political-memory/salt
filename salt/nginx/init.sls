nginx:
  pkg:
    - installed
  service.running:
    - require:
      - pkg: nginx

nginx-reload:
  cmd.wait:
    - name: service nginx reload

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/nginx.conf
