import os
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
    url = 'https://www.heppnetz.de/'
    r = requests.get(url)
    print("The first 200 characters from www.heppnetz.de are:")
    print(r.text[:200])
    print("\nDone.")


if __name__ == "__main__":
    typer.run(main)