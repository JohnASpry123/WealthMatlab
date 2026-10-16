"""Optional source audit (Python stdlib only); does not execute MATLAB.

Usage: python tests/check_census_sources.py /path/to/source-cache [--download]
This independent check audits the exact Census releases used by the MATLAB
builder. It prints source fingerprints and coverage, never research rankings.
"""
import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import urllib.request

FIPS = {1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,25,26,
        27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,
        48,49,50,51,53,54,55,56}
BASE = 'https://www2.census.gov/programs-surveys/popest/'
SOURCES = [
    (f'tables/1990-2000/intercensal/st-co/stch-icen{y}.txt', 'historical', [y])
    for y in (1997, 1998, 1999)
] + [
    ('datasets/2000-2010/intercensal/state/st-est00int-agesex.csv', 'intercensal', list(range(2000,2010))),
    ('datasets/2010-2020/state/asrh/SC-EST2020-ALLDATA6.csv', 'alldata6', list(range(2010,2020))),
    ('datasets/2020-2025/state/asrh/sc-est2025-alldata6.csv', 'alldata6', list(range(2020,2026))),
]

def audit(file, kind, years, return_population=False):
    counts = Counter()
    population = defaultdict(int)
    working = defaultdict(int)
    reported = {}
    seen = set()
    n = 0
    if kind == 'historical':
        with file.open() as stream:
            for line in stream:
                year, geo, age, race_sex, origin, value = map(int, line.split())
                assert year + 1900 == years[0] and geo % 1000 > 0
                assert 0 <= age <= 18 and 1 <= race_sex <= 8 and origin in (1,2) and value >= 0
                key = (geo, age, race_sex, origin)
                assert key not in seen, ('duplicate',key)
                seen.add(key); counts[geo] += 1; n += 1
                if geo // 1000 in FIPS:
                    k = (geo // 1000, years[0])
                    population[k] += value
                    if 4 <= age <= 13: working[k] += value
        assert set(counts.values()) == {304}, 'incomplete demographic county cells'
    else:
        with file.open(newline='',encoding='utf-8-sig') as stream:
            for row in csv.DictReader(stream):
                n += 1
                state, sex, age = (int(row[k]) for k in ('STATE','SEX','AGE'))
                if state not in FIPS or sex != 0: continue
                if kind == 'alldata6':
                    if int(row['ORIGIN']) != 0: continue
                    assert int(row['SUMLEV']) == 40
                    race = int(row['RACE']); assert 1 <= race <= 6
                    key = (state,age,race)
                else:
                    key = (state,age)
                assert key not in seen, ('duplicate',key)
                seen.add(key)
                if kind == 'intercensal' and age == 999:
                    for y in years: reported[state,y] = int(row[f'POPESTIMATE{y}'])
                    continue
                assert 0 <= age <= 85
                counts[state] += 1
                for y in years:
                    v = int(row[f'POPESTIMATE{y}']); assert v >= 0
                    population[state,y] += v
                    if 15 <= age <= 64: working[state,y] += v
        assert set(counts) == FIPS
        assert set(counts.values()) == ({516} if kind == 'alldata6' else {86})
        if kind == 'intercensal': assert dict(population) == reported
    expected = {(s,y) for s in FIPS for y in years}
    assert set(population) == set(working) == expected
    assert all(0 < working[k] <= population[k] for k in expected)
    if return_population:
        return dict(population), dict(working)
    return {'raw_rows':n, 'state_years':len(expected),
            'min_working_age_share':min(working[k]/population[k] for k in expected),
            'max_working_age_share':max(working[k]/population[k] for k in expected)}

def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source_dir',type=Path); ap.add_argument('--download',action='store_true')
    args=ap.parse_args(); args.source_dir.mkdir(parents=True,exist_ok=True)
    for path,kind,years in SOURCES:
        file=args.source_dir/Path(path).name
        if not file.exists():
            if not args.download: raise FileNotFoundError(file)
            with urllib.request.urlopen(BASE+path,timeout=120) as response:
                payload=response.read()
            file.write_bytes(payload)
        result={'file':file.name,'url':BASE+path,'sha256':hashlib.sha256(file.read_bytes()).hexdigest()}
        result.update(audit(file,kind,years))
        print(json.dumps(result),flush=True)

if __name__ == '__main__': main()
