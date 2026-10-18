#!/usr/bin/env python3
"""Tiny static server for build/web with no-cache headers.

No caching matters on a phone: otherwise Safari/Chrome happily keep an old
index.pck and you test stale code. Run via tools/serve_web.sh.
"""
import os
import socket
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web")
PORT = int(os.environ.get("PORT", "8060"))


class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "application/javascript",
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        super().end_headers()

    def log_message(self, fmt, *args):  # quieter log: method + path only
        sys.stdout.write("  %s\n" % (fmt % args))


def lan_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))  # no packets are sent; picks the LAN interface
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


if __name__ == "__main__":
    if not os.path.isfile(os.path.join(ROOT, "index.html")):
        print("build/web/index.html not found. Run tools/build_web.sh first.")
        sys.exit(1)
    print("Serving build/web")
    print(f"  On this Mac:            http://localhost:{PORT}/")
    print(f"  On your phone (same Wi-Fi): http://{lan_ip()}:{PORT}/")
    print("  Stop with Ctrl+C")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
