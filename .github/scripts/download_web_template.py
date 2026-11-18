"""Fetch only the official single-threaded web template from Godot's TPZ."""

import io
import os
import sys
import urllib.request
import zipfile

VERSION = "4.7.2"
URL = (
    "https://github.com/godotengine/godot-builds/releases/download/"
    f"{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"
)


class RemoteZip(io.RawIOBase):
    def __init__(self, url: str):
        self.url = url
        with urllib.request.urlopen(urllib.request.Request(url, method="HEAD"), timeout=45) as response:
            self.size = int(response.headers["Content-Length"])
        self.position = 0

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=os.SEEK_SET):
        if whence == os.SEEK_END:
            offset += self.size
        elif whence == os.SEEK_CUR:
            offset += self.position
        if not 0 <= offset <= self.size:
            raise ValueError("Seek outside archive")
        self.position = offset
        return offset

    def read(self, length=-1):
        if length < 0:
            length = self.size - self.position
        length = min(length, self.size - self.position)
        if length == 0:
            return b""
        start = self.position
        end = start + length - 1
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={start}-{end}"})
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206:
                raise RuntimeError("The release server did not honor a byte range request")
            data = response.read()
        if len(data) != length:
            raise IOError("Incomplete download from Godot release")
        self.position += length
        return data


def main():
    target_dir = sys.argv[1]
    os.makedirs(target_dir, exist_ok=True)
    with zipfile.ZipFile(RemoteZip(URL)) as archive:
        for filename in ("web_nothreads_release.zip", "version.txt"):
            matches = [item for item in archive.infolist() if item.filename.endswith("/" + filename)]
            if len(matches) != 1 or matches[0].file_size > 25_000_000:
                raise RuntimeError(f"Unexpected official template entry: {filename}")
            destination = os.path.join(target_dir, filename)
            with archive.open(matches[0]) as source, open(destination, "wb") as output:
                while chunk := source.read(1024 * 1024):
                    output.write(chunk)
            print(f"Downloaded {filename}: {os.path.getsize(destination)} bytes")


if __name__ == "__main__":
    main()
