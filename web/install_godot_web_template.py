#!/usr/bin/env python3
"""Install selected Godot Web templates from an official remote TPZ archive.

Godot 4.7's template manager reads individual members from the official TPZ
with HTTP range requests. This helper follows the same model so CI can install
the single-threaded Web template without downloading the complete archive.

Only Python's standard library is required. The ZIP CRC is checked while each
member is extracted, and installation is atomic.
"""

from __future__ import annotations

import argparse
import io
import os
import re
import shutil
import sys
import time
import urllib.error
import urllib.request
import zipfile
from collections import OrderedDict
from pathlib import Path
from typing import BinaryIO


CONTENT_RANGE_RE = re.compile(r"bytes\s+(\d+)-(\d+)/(\d+|\*)", re.IGNORECASE)
DEFAULT_TEMPLATE = "web_nothreads_release.zip"
USER_AGENT = "the-world-forgot-us-template-installer/1.0"


class DownloadError(RuntimeError):
    """Raised when a remote archive cannot be read safely."""


class RemoteRangeReader(io.RawIOBase):
    """Seekable, read-only view over an HTTP resource using byte ranges."""

    def __init__(
        self,
        url: str,
        *,
        timeout: float = 120.0,
        retries: int = 5,
        block_size: int = 4 * 1024 * 1024,
        cache_blocks: int = 10,
    ) -> None:
        super().__init__()
        self._source_url = url
        self._resolved_url = url
        self._timeout = timeout
        self._retries = retries
        self._block_size = block_size
        self._cache_blocks = cache_blocks
        self._cache: OrderedDict[int, bytes] = OrderedDict()
        self._position = 0
        self._size = self._discover_size_and_url()

    @property
    def size(self) -> int:
        return self._size

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def writable(self) -> bool:
        return False

    def tell(self) -> int:
        return self._position

    def seek(self, offset: int, whence: int = os.SEEK_SET) -> int:
        if whence == os.SEEK_SET:
            position = offset
        elif whence == os.SEEK_CUR:
            position = self._position + offset
        elif whence == os.SEEK_END:
            position = self._size + offset
        else:
            raise ValueError(f"Unsupported seek mode: {whence}")

        if position < 0:
            raise ValueError("Negative seek position")
        self._position = position
        return self._position

    def read(self, size: int = -1) -> bytes:
        if self.closed:
            raise ValueError("I/O operation on closed remote archive")
        if self._position >= self._size:
            return b""

        if size is None or size < 0:
            size = self._size - self._position
        else:
            size = min(size, self._size - self._position)
        if size == 0:
            return b""

        remaining = size
        parts: list[bytes] = []
        while remaining:
            block_index = self._position // self._block_size
            block_offset = self._position % self._block_size
            block = self._get_block(block_index)
            take = min(remaining, len(block) - block_offset)
            if take <= 0:
                raise DownloadError("Remote archive returned an incomplete block")
            parts.append(block[block_offset : block_offset + take])
            self._position += take
            remaining -= take
        return b"".join(parts)

    def close(self) -> None:
        self._cache.clear()
        super().close()

    def _request(self, url: str, start: int, end: int) -> urllib.request.Request:
        return urllib.request.Request(
            url,
            method="GET",
            headers={
                "Accept-Encoding": "identity",
                "Range": f"bytes={start}-{end}",
                "User-Agent": USER_AGENT,
            },
        )

    def _open_with_retry(
        self, request: urllib.request.Request
    ) -> BinaryIO:
        last_error: BaseException | None = None
        for attempt in range(self._retries):
            try:
                return urllib.request.urlopen(request, timeout=self._timeout)
            except (
                TimeoutError,
                urllib.error.HTTPError,
                urllib.error.URLError,
            ) as error:
                last_error = error
                if attempt + 1 == self._retries:
                    break
                time.sleep(min(2**attempt, 8))
        raise DownloadError(
            f"Request failed after {self._retries} attempts: {last_error}"
        )

    @staticmethod
    def _parse_content_range(value: str | None) -> tuple[int, int, int]:
        match = CONTENT_RANGE_RE.fullmatch(value.strip() if value else "")
        if not match or match.group(3) == "*":
            raise DownloadError(f"Invalid Content-Range header: {value!r}")
        return int(match.group(1)), int(match.group(2)), int(match.group(3))

    def _discover_size_and_url(self) -> int:
        request = self._request(self._source_url, 0, 0)
        with self._open_with_retry(request) as response:
            self._resolved_url = response.geturl()
            status = response.getcode()
            content_range = response.headers.get("Content-Range")

        # Some redirect handlers drop Range on the first request. Retry against
        # the resolved asset URL before declaring the host incompatible.
        if status != 206:
            request = self._request(self._resolved_url, 0, 0)
            with self._open_with_retry(request) as response:
                self._resolved_url = response.geturl()
                status = response.getcode()
                content_range = response.headers.get("Content-Range")

        if status != 206:
            raise DownloadError(
                "Template host does not support HTTP byte ranges "
                f"(expected 206, received {status})"
            )

        start, end, total = self._parse_content_range(content_range)
        if start != 0 or end != 0 or total <= 0:
            raise DownloadError(
                f"Unexpected discovery range: {start}-{end}/{total}"
            )
        return total

    def _get_block(self, block_index: int) -> bytes:
        cached = self._cache.pop(block_index, None)
        if cached is not None:
            self._cache[block_index] = cached
            return cached

        start = block_index * self._block_size
        end = min(start + self._block_size, self._size) - 1
        request = self._request(self._resolved_url, start, end)
        with self._open_with_retry(request) as response:
            status = response.getcode()
            content_range = response.headers.get("Content-Range")
            if status != 206:
                raise DownloadError(
                    f"Range request returned {status}; expected 206"
                )
            actual_start, actual_end, total = self._parse_content_range(
                content_range
            )
            if (actual_start, actual_end, total) != (start, end, self._size):
                raise DownloadError(
                    "Range response did not match the requested archive block"
                )
            data = response.read()

        expected_length = end - start + 1
        if len(data) != expected_length:
            raise DownloadError(
                f"Short range response: expected {expected_length}, got {len(data)}"
            )

        self._cache[block_index] = data
        while len(self._cache) > self._cache_blocks:
            self._cache.popitem(last=False)
        return data


def validate_template_name(name: str) -> str:
    if name != Path(name).name:
        raise ValueError(f"Template name must not contain a path: {name!r}")
    if not name.startswith("web_") or not name.endswith(".zip"):
        raise ValueError(f"Expected a Godot Web template ZIP, received {name!r}")
    return name


def install_templates(
    archive_url: str,
    output_dir: Path,
    templates: list[str],
    *,
    force: bool,
    timeout: float,
    retries: int,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    reader = RemoteRangeReader(
        archive_url,
        timeout=timeout,
        retries=retries,
    )
    archive_size_mib = reader.size / (1024 * 1024)
    print(f"Reading official template archive ({archive_size_mib:.1f} MiB remote)")

    try:
        with zipfile.ZipFile(reader, mode="r") as archive:
            for template in templates:
                member_name = f"templates/{validate_template_name(template)}"
                try:
                    member = archive.getinfo(member_name)
                except KeyError as error:
                    raise DownloadError(
                        f"{member_name!r} is not present in the archive"
                    ) from error

                target = output_dir / template
                if target.is_file() and target.stat().st_size > 0 and not force:
                    print(f"Already installed: {target}")
                    continue

                temporary = target.with_name(f".{target.name}.part")
                temporary.unlink(missing_ok=True)
                try:
                    with archive.open(member, mode="r") as source:
                        with temporary.open("wb") as destination:
                            shutil.copyfileobj(
                                source,
                                destination,
                                length=1024 * 1024,
                            )
                    if temporary.stat().st_size != member.file_size:
                        raise DownloadError(
                            f"Extracted size mismatch for {template}"
                        )
                    os.replace(temporary, target)
                finally:
                    temporary.unlink(missing_ok=True)

                size_mib = target.stat().st_size / (1024 * 1024)
                print(f"Installed {target} ({size_mib:.1f} MiB)")
    finally:
        reader.close()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Install selected Godot Web templates from an official remote TPZ "
            "using HTTP range requests."
        )
    )
    parser.add_argument(
        "--archive-url",
        required=True,
        help="Official Godot export_templates.tpz URL.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Godot version-specific export_templates directory.",
    )
    parser.add_argument(
        "--template",
        action="append",
        dest="templates",
        default=[],
        help=(
            "Template filename to install. Repeat for multiple files. "
            f"Default: {DEFAULT_TEMPLATE}"
        ),
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace an existing template file.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=120.0,
        help="Per-request timeout in seconds (default: 120).",
    )
    parser.add_argument(
        "--retries",
        type=int,
        default=5,
        help="Number of attempts per request (default: 5).",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    templates = args.templates or [DEFAULT_TEMPLATE]
    if args.retries < 1:
        parser.error("--retries must be at least 1")
    if args.timeout <= 0:
        parser.error("--timeout must be positive")

    try:
        install_templates(
            args.archive_url,
            args.output_dir.expanduser(),
            templates,
            force=args.force,
            timeout=args.timeout,
            retries=args.retries,
        )
    except (DownloadError, OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
