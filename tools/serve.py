"""Serve the exported game on localhost; no installation or external services needed."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from functools import partial
from pathlib import Path
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=8066)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1] / "build" / "web"
class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()
    def log_message(self, *_args):
        pass

if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", args.port), partial(Handler, directory=str(root)))
    print(f"Window Hero: http://127.0.0.1:{args.port}", flush=True)
    server.serve_forever()
