"""
Manage the Django secret key

Store the key in the file system.  If the key exists and has open permissions,
recreate it.  If the key does not exist, create it and set the permissions.
"""
# This script is written for readability, not for performance.
import os

from django.core.management.utils import get_random_secret_key

DJANGO_SECRET_KEY_FILE = os.environ.get(
    "DJANGO_SECRET_KEY_FILE", "/tmp/django-secret-key"
)


def get_secret_key() -> str:
    "Return an approved secret key"
    if secret_key_file_exists():
        try:
            if not secret_key_file_is_mine():
                delete_secret_key_file()
                generate_new_secret_key_file()
            if not secret_key_file_is_private():
                delete_secret_key_file()
                generate_new_secret_key_file()
            elif not secret_key_file_has_fifty_characters():
                delete_secret_key_file()
                generate_new_secret_key_file()
            # If the secret key file exists,
            # is not world-readable and
            # contains 50 characters,
            # it is not recreated.
        except FileNotFoundError:
            generate_new_secret_key_file()
    else:
        generate_new_secret_key_file()
    return read_secret_key()


def delete_secret_key_file() -> None:
    "Delete the secret key file"
    os.unlink(DJANGO_SECRET_KEY_FILE)


def generate_new_secret_key_file() -> None:
    "Generate a new secret key and write it to the secret key file"
    # Prepare the secret key file descriptor.  This is necessary so that the
    # file permissions are correct before any secret key is written to the
    # file.
    secret_key_fd = os.open(
        DJANGO_SECRET_KEY_FILE, os.O_WRONLY | os.O_CREAT, 0o640
    )

    # Open the file descriptor for writing.
    with open(secret_key_fd, "w", encoding="UTF-8") as secret_key:
        # Write the secret key to the file.
        secret_key.write(get_random_secret_key())


def read_secret_key() -> str:
    "Read the secret key file and return the secret_key"
    # Read the secret key from the secret key file.
    with open(DJANGO_SECRET_KEY_FILE, "r", encoding="UTF-8") as secret_key:
        return secret_key.read()


def secret_key_file_exists() -> bool:
    "Return True if the secret key file exists"
    return os.path.exists(DJANGO_SECRET_KEY_FILE)


def secret_key_file_has_fifty_characters() -> bool:
    "Read the secret key file; return True if the file contains 50 characters"
    # Read the secret key from the secret key file.
    secret_key = read_secret_key()

    # Remove any trailing newline characters.
    clean_secret_key = secret_key.rstrip()

    # Return true if the length of the cleaned secret key is 50 characters.
    return len(clean_secret_key) == 50


def secret_key_file_is_private() -> bool:
    "Return True if the secret key file is private"
    # Get the file mode from stat()
    key_stat = os.stat(DJANGO_SECRET_KEY_FILE)

    # In file modes, global permissions are the last 3 bits: rwx.
    # To test for global readability, test the third bit: 0o4
    # A bitwise-and on that value, converted to boolean should give a
    # boolean showing whether it is globally readable.
    globally_readable = bool(key_stat.st_mode & 0o4)

    # Private is the opposite of globally readable.
    return not globally_readable


def secret_key_file_is_mine() -> bool:
    "Return True if the secret key file is globally readable"
    # Get the file mode from stat()
    key_stat = os.stat(DJANGO_SECRET_KEY_FILE)

    # The user ID of the file should match the user ID of this process.
    uid_ok = key_stat.st_uid == os.getuid()

    # The group ID of the file should match the group ID of this process.
    gid_ok = key_stat.st_gid == os.getgid()

    return uid_ok and gid_ok


if __name__ == "__main__":
    print(get_secret_key())
