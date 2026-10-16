"""Compatibility entry point for the shared, independently validated parser."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from census_sources import FIPS, BASE, SOURCES, audit, main

if __name__ == '__main__':
    main()
