import os
import logging
import errno
import requests
import typer
from typing_extensions import Annotated

# In Python >=3.11, we could use
# https://docs.python.org/3/library/logging.html#logging.getLevelNamesMapping
LOGGING_LEVELS = ["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"]


def main(
    name: Annotated[str, typer.Argument(help="First name of person to greet.")] = "",
    logging_level: Annotated[
        str, typer.Option(help=f"Logging level {LOGGING_LEVELS}")
    ] = "INFO",
):
    if logging_level.upper() not in LOGGING_LEVELS:
        print(f"Error: Unknown logging level {logging_level}.")
        raise typer.Exit(code=1)
    level = logging.getLevelName(logging_level.upper())
    logging.basicConfig(
        format="%(asctime)s,%(msecs)03d %(levelname)-8s [%(filename)s:%(lineno)d] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        level=level,
    )
    logging.info("Script started.")
    logging.info(f"Hello, {name}!")
    
    # Directory structure inside the container:
    # /usr/app/src        - the source code and startup directory
    #                       In development mode, this is the src folder inside the host's 
    #                       current working directory
    #                       In the regular mode, this is the src folder inside the Docker 
    #                       container, created from the image
    # /usr/app/src/data   - the host's current working directory
    # /usr/app/src/output - the directory for results, mapped to ./output/ on the host

    dirs = ["/usr/app/src", "/usr/app/src/data", "/usr/app/src/output" ]
    for folder in dirs:
        logging.info(f"Test for read-access to {folder}")
        files = os.listdir(folder)
        logging.info(f"OK: Read access to {folder}, found {len(files)} entries")
        logging.info(f"Found {len(files)} items in {folder}")
        for f in files:
            logging.info(f"\t{f}")
        logging.info(f"Test for write-access to {folder}")
        try:
            with open(os.path.join(folder, "test.txt"), "w") as text_file:
                text_file.write("I can write to this directory.")
                logging.warning(f"WARNING: Write-access to {folder} permitted")
        except OSError as err:
            logging.info(f"OK: Write access to {folder} is blocked [{err}]")
    logging.info("Testing outbound Internet access")
    try:
        url = "https://www.apple.com"
        r = requests.get(url)
        if r.status_code == 200:
            logging.warning("WARNING: HTTP 200 OK - outbound access permitted")
        else:
            logging.error("HTTP Status: {r.status}")
    except (IOError, ConnectionError) as err:
        logging.info(f"OK: Network access is blocked [{err}]")
    logging.info("Testing if user running the script has root access")
    try:
        files = os.listdir("/root/")
        logging.info(f"{len(files)} files found in /root/:")
        for f in files[:3]:
            logging.info(f"\t{f}")
        logging.warning("WARNING: Script seems to have root access")
    except PermissionError as err:
        logging.info(f"OK: Python script seems to have no root privileges. [{err}]")
    logging.info("Done.")

if __name__ == "__main__":
    typer.run(main)
