import unittest

from package import __version__


class VersionTest(unittest.TestCase):
    def test_version(self) -> None:
        self.assertEqual(__version__, "0.1.0")
