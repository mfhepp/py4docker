import os
import logging
import errno
import requests
import typer
from typing_extensions import Annotated

# In Python >=3.11, we could use 
# https://docs.python.org/3/library/logging.html#logging.getLevelNamesMapping
LOGGING_LEVELS = ["CRITICAL", "ERROR", "WARNING", "INFO",  "DEBUG"]


def main(name: Annotated[str, typer.Argument(help="First name of person to greet.")] = "",
        logging_level: Annotated[str, 
        typer.Option(help=f"Logging level {LOGGING_LEVELS}")] = "INFO"):
    if logging_level.upper() not in LOGGING_LEVELS:
        print(f"Error: Unknown logging level {logging_level}.")
        raise typer.Exit(code=1)
    level = logging.getLevelName(logging_level.upper())
    logging.basicConfig(
        format="%(asctime)s,%(msecs)03d %(levelname)-8s [%(filename)s:%(lineno)d] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        level=level)
    logging.info("Script started.")
    logging.info(f"Hello, {name}!")
    logging.info("Test for read-access to the current working directory,  which is mapped as ./data/")
    files = os.listdir('data/')
    logging.info("Read access ok.")
    logging.info(f"Found {len(files)} files in the current working directory.")
    for f in files:
        logging.info(f"\t{f}")
    logging.info("Test for write access to the current working directory.")
    try:
        with open ("data/test.txt", 'w') as text_file:
            text_file.write("I can write to the read-only directory.")
            logging.warning("Error: I can write to the read-only directory.")
    except OSError as err:
        logging.info(f"OK: Write access is blocked. [{err}]")
    logging.info("Test for write access to the output directory.")
    try:
        with open ("output/test.txt", 'w') as text_file:
            text_file.write("I can write to the output directory.")
            logging.info("OK: I can write to the output directory.")
    except OSError as err:
        logging.error(f"Write access to output/ is blocked. [{err}]")
    logging.info("Test for outbound Internet access:")
    try:
        url = 'https://www.apple.com'
        r = requests.get(url)
        if r.status_code == 200:
            logging.warning("HTTP 200 OK - outbound access permitted.")
        else:
            logging.error("HTTP Status: {r.status}")
    except (IOError, ConnectionError) as err:
        logging.info(f"OK: Network access is blocked. [{err}]")
    logging.info("Testing if user has root access.")
    try:
        files = os.listdir('/root/')
        logging.info(f"{len(files)} files found in /root/:")
        for f in files:
            logging.info(f"\t{f}")
        logging.warning("Script seems to have root access.")
    except PermissionError as err:
        logging.info(f"OK: Python script seems to have no root privileges. [{err}]")
    logging.info("Done.")


if __name__ == "__main__":
    typer.run(main)