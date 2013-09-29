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
  pip.installed:
    - names:
      - debug
    - require:
      - pkg: python-pip
