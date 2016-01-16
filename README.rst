abs2pkgix
=========

Experimental converter from `ArchLinux <https://www.archlinux.org>`_ packages
to `pkgix <https://github.com/pkgix/pkigx>`_.

Usage:

.. code:: sh

    abs
    bin/abs2pkgix

Then point pkgix to the repo:

.. code:: sh

    export PKGIX_REPOS="http://localhost:8080/pkgs"
    # use pkgix
