from pathlib import Path
from setting import MODULE_DIR, PACKAGE_DIR
from common import get_timestamp
import zipfile, sys

EXT = "bam"

def pack(module_name:str):
    module_path = MODULE_DIR / module_name
    if module_path.exists():
        bam_file = f"{get_timestamp()}_{module_name}.{EXT}"
        bam_path = PACKAGE_DIR / bam_file
        with zipfile.ZipFile(bam_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for file in Path(module_path).rglob("*"):
                zf.write(filename=file, arcname=file.name) # arcname write the file to the root
        if bam_path.exists() and len(zf.namelist()) != 0:
            print(f"{bam_file} has been pack successfully.")
            print("Content:")
            for name in zf.namelist():
                print(f" - {name}")
        else:
            raise zipfile.BadZipfile(f"Failed to pack {bam_file}")
    else:
        raise FileNotFoundError(f"The specified path does not exist: {module_path}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python pack.py <module_name>")
        sys.exit(0)
    else:
        try:
            module_name = str(sys.argv[1])
            pack(module_name=module_name)
        except (FileNotFoundError, zipfile.BadZipfile) as e:
            print(e)

if __name__ == "__main__":
    main()
    