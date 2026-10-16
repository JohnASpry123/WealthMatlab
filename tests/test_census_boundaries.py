"""Offline regression tests: synthetic cases plus the committed Census snapshot."""
import csv
import json
import math
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from audit_census_boundaries import (FIPS, YEARS, diagnose, log_change, validate,
                                     heatmap, overlap_plot, write_csv)
from census_sources import audit

ROOT=Path(__file__).resolve().parents[1]


def fixture():
    # Linear counts yield smooth annual growth; all inputs are artificial.
    pop={(s,y):100000+(y-1997)*1000 for s in FIPS for y in YEARS}
    working={k:int(v*0.6) for k,v in pop.items()}
    overlaps={(m,s,y):d[s,y] for m,d in [('total',pop),('working_age',working)]
              for s in FIPS for y in (2010,2020)}
    return pop,working,overlaps


class BoundaryAudit(unittest.TestCase):
    def test_smooth_demography_is_not_flagged(self):
        annual,rows=diagnose(*fixture())
        self.assertEqual(len(annual),2800)
        self.assertEqual(len(rows),300)
        self.assertFalse(any(r['unusual'] for r in rows))
        self.assertTrue(all(r['same_year_revision_log_pp']==0 for r in rows if r['boundary_year']!=2000))

    def test_persistent_splice_separates_revision_from_growth(self):
        p,w,o=fixture()
        for s,y in p:
            if s==1 and y>=2020: p[s,y]*=2; w[s,y]*=2
        _,rows=diagnose(p,w,o)
        r=next(r for r in rows if r['fips']==1 and r['metric']=='total' and r['boundary_year']==2020)
        self.assertTrue(r['unusual'])
        self.assertAlmostEqual(r['same_year_revision_log_pp'],100*math.log(2))
        self.assertAlmostEqual(r['observed_log_pp'],r['old_release_growth_log_pp']+r['same_year_revision_log_pp'])

    def test_actual_jump_with_no_revision_is_not_called_revision(self):
        p,w,o=fixture()
        for s,y in p:
            if s==1 and y>=2020: p[s,y]*=2; w[s,y]*=2
        o['total',1,2020]=p[1,2020]; o['working_age',1,2020]=w[1,2020]
        _,rows=diagnose(p,w,o)
        r=next(r for r in rows if r['fips']==1 and r['metric']=='total' and r['boundary_year']==2020)
        self.assertTrue(r['unusual'])
        self.assertEqual(r['interpretation'],'small_same_year_revision')

    def test_missing_overlap_stays_unresolved(self):
        p,w,o=fixture(); p[1,2000]*=2
        _,rows=diagnose(p,w,o)
        r=next(r for r in rows if r['fips']==1 and r['metric']=='total' and r['boundary_year']==2000)
        self.assertEqual(r['interpretation'],'unresolved_outlier')
        self.assertIsNone(r['same_year_revision_log_pp'])

    def test_interior_changes_cancel_but_endpoints_do_not(self):
        x=[100,110,120,130,140]; z=[100,110,180,130,140]
        meanlog=lambda v:sum(log_change(a,b) for a,b in zip(v,v[1:]))/(len(v)-1)
        simple=lambda v:sum(b/a-1 for a,b in zip(v,v[1:]))/(len(v)-1)
        self.assertAlmostEqual(meanlog(x),meanlog(z))
        self.assertNotAlmostEqual(simple(x),simple(z))
        self.assertNotAlmostEqual(meanlog(x[:3]),meanlog(z[:3]))
        z[-1]*=1.1
        self.assertAlmostEqual(meanlog(z)-meanlog(x),100*math.log(1.1)/4)

    def test_invalid_grid_and_counts_fail(self):
        p,w,_=fixture(); del p[1,1997]
        with self.assertRaises(ValueError): validate(p,w)
        for bad in (0,-1,float('nan'),float('inf'),1.5):
            p,w,_=fixture(); p[1,1997]=bad
            with self.assertRaises(ValueError): validate(p,w)
        p,w,_=fixture(); w[1,1997]=p[1,1997]+1
        with self.assertRaises(ValueError): validate(p,w)

    def test_snapshot_reproduces_diagnostics(self):
        base=ROOT/'reports/census_boundaries'
        with (base/'population_panel.csv').open() as f: panel=list(csv.DictReader(f))
        with (base/'boundary_diagnostics.csv').open() as f: expected=list(csv.DictReader(f))
        p={(int(r['fips']),int(r['year'])):int(r['total']) for r in panel}
        w={(int(r['fips']),int(r['year'])):int(r['working_age']) for r in panel}
        o={(r['metric'],int(r['fips']),int(r['boundary_year'])):int(r['old_release_boundary_population'])
           for r in expected if r['old_release_boundary_population']}
        annual,rows=diagnose(p,w,o)
        with tempfile.TemporaryDirectory() as temp:
            for name,data in [('boundary_diagnostics.csv',rows),('annual_changes.csv',annual)]:
                path=Path(temp)/name; write_csv(path,data)
                self.assertEqual(path.read_bytes(),(base/name).read_bytes())
            heatmap(Path(temp)/'heat.svg',rows); overlap_plot(Path(temp)/'overlap.svg',rows)
            for name in ('heat.svg','overlap.svg'): ET.parse(Path(temp)/name)
        with (ROOT/'tests/census_source_audit_2026-10-16.jsonl').open() as f:
            old={r['file']:r['sha256'] for r in map(json.loads,f)}
        current=json.loads((base/'source_manifest.json').read_text())
        self.assertEqual(old,{r['file']:r['sha256'] for r in current})

    def test_overlap_parser_uses_july_estimate_and_inclusive_working_age(self):
        with tempfile.TemporaryDirectory() as temp:
            path=Path(temp)/'synthetic.csv'
            rows=[]
            for state in FIPS:
                for age in range(86):
                    rows.append(dict(STATE=state,SEX=0,AGE=age,POPESTIMATE2010=10,ESTIMATESBASE2010=999))
                rows.append(dict(STATE=state,SEX=0,AGE=999,POPESTIMATE2010=860,ESTIMATESBASE2010=999))
            write_csv(path,rows)
            p,w=audit(path,'intercensal',[2010],return_population=True)
            self.assertEqual(p[1,2010],860); self.assertEqual(w[1,2010],500)
            rows.append(rows[0]); write_csv(path,rows)
            with self.assertRaises(AssertionError): audit(path,'intercensal',[2010],return_population=True)

if __name__=='__main__': unittest.main()
