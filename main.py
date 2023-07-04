import os
import errno
import requests
import typer


def main(name: str):
    print(f"Hello, {name}!")
    print("-" * 60)
    print()
    print("Test for read-access to the current working directory,  which is mapped as ./data/")
    print("-" * 60)
    files = os.listdir('data/')
    print(f"{len(files)} files in the current working directory:")
    for f in files:
        print(f"\t{f}")
    print()
    print("Test for write access to the current working directory:")
    print("-" * 60)
    with open ("data/test.txt", 'w') as text_file:
        text_file.write("I can write to this directory.")
        print("I can write to this directory.")
    print()
    print("Test for outbound Internet access:")
    print("-" * 60)
    try:
        url = 'https://www.apple.com'
        r = requests.get(url)
        if r.status == 200:
            print("HTTP 200 OK")
        else:
            print("HTTP Status: {r.status}")
    except (IOError, ConnectionError) as err:
        print(f"Network access is blocked. [{err}]")
    print()
    print("Test if user has root access:")
    print("-" * 60)
    try:
        files = os.listdir('/root/')
        print(f"{len(files)} files found in /root/:")
        for f in files:
            print(f"\t{f}")
        print("Warning: Script seems to have root access.")
    except PermissionError as err:
        print(f"OK: Python script seems to have no root privileges. [{err}]")

    print("\nDone.")


if __name__ == "__main__":
    typer.run(main)