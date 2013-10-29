base-pkgs:
  pkg.installed:
    - names:
      - git
      - python
      - wget
      - htop
      - screen
      - tig
      - locate
      - python-pip
      - net-tools
      - strace
      - curl
  pip.installed:
    - names:
      - debug
      - pg_activity
    - require:
      - pkg: python-pip
