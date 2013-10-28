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
  pip.installed:
    - names:
      - debug
    - require:
      - pkg: python-pip
