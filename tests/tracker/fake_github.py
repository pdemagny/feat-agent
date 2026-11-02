"""Fake GitHub GraphQL endpoint for tests/tracker, served on a unix socket.

Usage: python3 -I fake_github.py <socket> <case dir>

For POST .../graphql: reads the operation name from the document, appends
{"op", "variables", "query"} as one JSON line to <case>/requests, then
answers 502 once if <case>/<Op>.fail exists (and removes it), else
<case>/<Op>.json with 200 (plus X-OAuth-Scopes from <case>/scopes when that
file exists), else a GraphQL errors body. Applies no mutation.
"""

import http.server
import json
import os
import re
import socketserver
import sys

SOCKET, CASE = sys.argv[1], sys.argv[2]
OP = re.compile(r"\b(?:query|mutation)\s+([A-Za-z_][A-Za-z0-9_]*)")


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def answer(self, code, body, scopes=None):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        if scopes is not None:
            self.send_header("X-OAuth-Scopes", scopes)
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        req = json.loads(self.rfile.read(length) or b"{}")
        query = req.get("query", "")
        m = OP.search(query)
        op = m.group(1) if m else ""
        with open(os.path.join(CASE, "requests"), "a") as f:
            line = {"op": op, "variables": req.get("variables"), "query": query}
            f.write(json.dumps(line) + "\n")
        fail = os.path.join(CASE, op + ".fail")
        fixture = os.path.join(CASE, op + ".json")
        if op and os.path.exists(fail):
            os.remove(fail)
            self.answer(502, '{"message":"Bad Gateway"}')
        elif op and os.path.exists(fixture):
            scopes = None
            scopes_file = os.path.join(CASE, "scopes")
            if os.path.exists(scopes_file):
                with open(scopes_file) as f:
                    scopes = f.read().strip()
            with open(fixture) as f:
                self.answer(200, f.read(), scopes)
        else:
            err = {"type": "NOT_FOUND", "message": "fake_github: no fixture for " + (op or "?")}
            self.answer(200, json.dumps({"data": None, "errors": [err]}))


class Server(socketserver.UnixStreamServer):
    def get_request(self):
        conn, _ = super().get_request()
        return conn, ("fake", 0)


if __name__ == "__main__":
    with Server(SOCKET, Handler) as server:
        server.serve_forever()
