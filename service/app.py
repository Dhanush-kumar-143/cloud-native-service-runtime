
import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

def get_config_value(filename, env_name, default):
    config_file = Path("/etc/demo-config") / filename

    try:
        value = config_file.read_text().strip()
        if value:
            return value
    except OSError:
        pass

    return os.getenv(env_name, default)

class RequestHandler(BaseHTTPRequestHandler):

    def send_json(self, status_code, data):
        response = json.dumps(data).encode("utf-8")

        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)

    def do_GET(self):
        if self.path == "/":
            self.send_json(200, {
                "app": get_config_value("appName", "APP_NAME", "demo-app"),
                "version": get_config_value("version", "VERSION", "1.0.0"),
                "pod": socket.gethostname()
             })

        elif self.path == "/healthz":
            self.send_json(200, {
                "status": "healthy"
            })

        else:
            self.send_json(404, {
                "error": "Not Found"
            })


if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", 8080), RequestHandler)
    print("Application listening on port 8080")
    server.serve_forever()
