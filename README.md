Django + PostgreSQL in Sandstorm
================================

This repository demonstrates how to build and run a minimal Django application
with PostgreSQL in Sandstorm.

The interesting files are in the `.sandstorm` directory.

Python
------

This application will, by default, compile Python 3.12 from source.  This is
desirable for performance and supporting the latest version of Django.  If you
desire to use Python 3.9, as shipped with Debian Bullseye, please update
`PYTHON_BUILD_FROM_SOURCE` in `.sandstorm/setup.sh` and `PYTHON` and
`PYTHON_PLUS_VERSION` in `.sandstorm/environment`.

Python 3.9 will be supported through October, 2025.

Python 3.12 will be supported through October, 2028.

Django 4.2 LTS supports Python 3.9 - 3.12 and will be supported through April,
2026.

Django 5 supports Python 3.10 - 3.12 and will be supported through April, 2025.  Django 5.2 LTS is expected in April, 2025 and will be supported through April, 2028.

For details, consult the [Python release
cycle](https://devguide.python.org/versions/#versions) and the [Django
Downloads page](https://www.djangoproject.com/download/#supported-versions).

License
-------

The files in the repository are dual-licensed under the MIT and Apache 2.0
licenses, with the exception of the `util` directory, which contains its own
release from copyright (CC0).
