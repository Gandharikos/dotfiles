from sample_python import __version__, greeting


def test_greeting() -> None:
    assert greeting("Python") == "Hello, Python!"


def test_version() -> None:
    assert __version__ == "0.1.0"
