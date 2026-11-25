"""Opt-in real-core test; run with ADGUARDHOME_TEST_BINARY inside an isolated Linux netns."""

import ipaddress
import json
import os
from pathlib import Path
import socket
import struct
import subprocess
import tempfile
import threading
import time
import unittest


@unittest.skipUnless(os.environ.get("ADGUARDHOME_TEST_BINARY"), "requires isolated real AdGuard core")
class AdGuardShortNameTests(unittest.TestCase):
    def test_exact_lan_rewrite(self):
        # Fail closed before binding anything in a production network namespace.
        self.assertNotEqual(os.readlink("/proc/self/ns/net"), os.readlink("/proc/1/ns/net"))
        subprocess.run(["ip", "link", "set", "lo", "up"], check=True)
        stop = threading.Event()
        upstream = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        upstream.bind(("127.0.0.1", 19053))
        upstream.settimeout(0.2)

        def serve():
            while not stop.is_set():
                try:
                    packet, peer = upstream.recvfrom(4096)
                except socket.timeout:
                    continue
                pos, labels = 12, []
                while packet[pos]:
                    size = packet[pos]
                    labels.append(packet[pos + 1 : pos + 1 + size].decode())
                    pos += 1 + size
                end = pos + 5
                qtype = struct.unpack("!H", packet[pos + 1 : pos + 3])[0]
                name = ".".join(labels).lower()
                address = "2001:2::99" if qtype == 28 else "198.18.0.99"
                if name == "heimdall.tail2cfd9e.ts.net" and qtype == 1:
                    address = "100.76.84.51"
                packed = ipaddress.ip_address(address).packed
                header = packet[:2] + struct.pack("!HHHHH", 0x8180, 1, 1, 0, 0)
                answer = b"\xc0\x0c" + struct.pack("!HHIH", qtype, 1, 60, len(packed)) + packed
                upstream.sendto(header + packet[12:end] + answer, peer)

        worker = threading.Thread(target=serve, daemon=True)
        worker.start()

        def query(name, qtype, tcp=False):
            qname = b"".join(bytes([len(label)]) + label.encode() for label in name.rstrip(".").split(".")) + b"\0"
            question = struct.pack("!HHHHHH", 1234, 0x100, 1, 0, 0, 0) + qname + struct.pack("!HH", qtype, 1)
            kind = socket.SOCK_STREAM if tcp else socket.SOCK_DGRAM
            with socket.socket(socket.AF_INET, kind) as sock:
                sock.settimeout(1)
                sock.connect(("127.0.0.1", 19054))
                if tcp:
                    sock.sendall(struct.pack("!H", len(question)) + question)

                    def exact(size):
                        data = b""
                        while len(data) < size:
                            chunk = sock.recv(size - len(data))
                            if not chunk:
                                raise EOFError("short DNS response")
                            data += chunk
                        return data

                    response = exact(struct.unpack("!H", exact(2))[0])
                else:
                    sock.send(question)
                    response = sock.recv(4096)
            return response

        try:
            with tempfile.TemporaryDirectory(prefix="adguard-shortname-") as directory:
                config = {
                    "schema_version": 34,
                    "http": {"address": "127.0.0.1:19055"},
                    "dns": {
                        "bind_hosts": ["127.0.0.1"], "port": 19054,
                        "upstream_dns": ["127.0.0.1:19053"],
                        "hostsfile_enabled": False, "cache_enabled": False,
                        "ratelimit": 0,
                    },
                    "filtering": {
                        "protection_enabled": True, "rewrites_enabled": True,
                        "rewrites": [{"domain": "heimdall", "answer": "192.168.8.2", "enabled": True}],
                    },
                    "filters": [],
                }
                path = Path(directory) / "config.yaml"
                path.write_text(json.dumps(config))  # JSON is valid YAML.
                with open(Path(directory) / "core.log", "wb") as log:
                    process = subprocess.Popen(
                        [os.environ["ADGUARDHOME_TEST_BINARY"], "--no-check-update", "-c", str(path), "-w", directory],
                        stdout=log, stderr=subprocess.STDOUT,
                    )
                    try:
                        for _ in range(100):
                            self.assertIsNone(process.poll(), "AdGuard exited during isolated startup")
                            try:
                                query("heimdall", 1)
                                break
                            except (OSError, EOFError):
                                time.sleep(0.1)
                        else:
                            self.fail("isolated AdGuard readiness timed out")
                        for tcp in (False, True):
                            for name in ("heimdall", "HeImDaLl."):
                                response = query(name, 1, tcp)
                                self.assertEqual(struct.unpack("!H", response[2:4])[0] & 15, 0)
                                self.assertEqual(struct.unpack("!H", response[6:8])[0], 1)
                                self.assertIn(ipaddress.ip_address("192.168.8.2").packed, response)
                                response = query(name, 28, tcp)
                                self.assertEqual(struct.unpack("!H", response[2:4])[0] & 15, 0)
                                self.assertEqual(struct.unpack("!H", response[6:8])[0], 0)
                            for name, expected in (
                                ("heimdall.tail2cfd9e.ts.net", "100.76.84.51"),
                                ("heimdall.example", "198.18.0.99"),
                                ("notheimdall", "198.18.0.99"),
                            ):
                                self.assertIn(ipaddress.ip_address(expected).packed, query(name, 1, tcp))
                    finally:
                        process.terminate()
                        process.wait(timeout=10)
        finally:
            stop.set()
            worker.join(timeout=2)
            upstream.close()


if __name__ == "__main__":
    unittest.main()
