"Load Django settings before launching Uvicorn"
import os

import django
import uvicorn

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "django_project.settings")
django.setup()

if __name__ == "__main__":
    uvicorn.run(
        "django_project.asgi:application",
        log_level="info",
        port=0,
        proxy_headers=True,
        uds="/var/run/uvicorn.sock",
    )
