"""Offline Census boundary audit; stdlib only. See CENSUS_BOUNDARY_AUDIT.md."""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import statistics
from xml.sax.saxutils import escape
from census_sources import BASE, SOURCES, FIPS, audit

BOUNDARIES = (2000, 2010, 2020)
YEARS = tuple(range(1997, 2026))
NAMES = ('Alabama|Alaska|Arizona|Arkansas|California|Colorado|Connecticut|Delaware|Florida|Georgia|Hawaii|Idaho|Illinois|Indiana|Iowa|Kansas|Kentucky|Louisiana|Maine|Maryland|Massachusetts|Michigan|Minnesota|Mississippi|Missouri|Montana|Nebraska|Nevada|New Hampshire|New Jersey|New Mexico|New York|North Carolina|North Dakota|Ohio|Oklahoma|Oregon|Pennsylvania|Rhode Island|South Carolina|South Dakota|Tennessee|Texas|Utah|Vermont|Virginia|Washington|West Virginia|Wisconsin|Wyoming').split('|')
STATES = dict(zip(sorted(FIPS), NAMES))


def log_change(previous, current):
    if not (math.isfinite(previous) and math.isfinite(current) and previous > 0 and current > 0):
        raise ValueError('Population must be finite and positive')
    return 100 * math.log(current / previous)


def validate(pop, working):
    expected = {(s, y) for s in FIPS for y in YEARS}
    if set(pop) != expected or set(working) != expected:
        raise ValueError('Require the complete 50-state 1997–2025 grid')
    for k in expected:
        if not (math.isfinite(pop[k]) and math.isfinite(working[k]) and
                0 < working[k] <= pop[k] and int(pop[k]) == pop[k] and int(working[k]) == working[k]):
            raise ValueError('Invalid population counts')


def diagnose(pop, working, overlaps):
    """Return annual changes and boundary diagnostics; never smooth or replace data.

    overlaps[(metric, state, year)] is an old-release July 1 boundary-year count.
    Reference: up to 3 annual intervals on either side, excluding splice years.
    A flag requires both >=0.5 log percentage points and >=3 robust sigmas.
    Sigma is 1.4826*MAD, floored at 0.1 log percentage points.
    """
    validate(pop, working)
    annual, diagnostic = [], []
    for metric, series in [('total', pop), ('working_age', working)]:
        for state in sorted(FIPS):
            rates = {y: log_change(series[state,y-1], series[state,y]) for y in YEARS[1:]}
            for year, rate in rates.items():
                annual.append(dict(fips=state, state=STATES[state], metric=metric, year=year,
                                   population=series[state,year], previous_population=series[state,year-1],
                                   change_persons=series[state,year]-series[state,year-1],
                                   simple_percent=100*(series[state,year]/series[state,year-1]-1),
                                   log_percentage_points=rate, boundary=year in BOUNDARIES))
            for year in BOUNDARIES:
                neighbors = [rates[y] for y in rates if 0 < abs(y-year) <= 3 and y not in BOUNDARIES]
                center = statistics.median(neighbors)
                mad = statistics.median(abs(x-center) for x in neighbors)
                scale = max(0.1, 1.4826*mad)
                residual = rates[year]-center
                flag = abs(residual) >= max(0.5, 3*scale)
                old = overlaps.get((metric,state,year))
                within = log_change(series[state,year-1],old) if old is not None else None
                revision = log_change(old,series[state,year]) if old is not None else None
                if revision is not None:
                    if not math.isclose(rates[year],within+revision,abs_tol=1e-10):
                        raise ValueError('Overlap decomposition does not reconcile')
                    interpretation = ('material_same_year_revision' if abs(revision) >= 0.5 else
                                      'small_same_year_revision')
                else:
                    interpretation = 'unresolved_outlier' if flag else 'consistent_with_local_trend'
                diagnostic.append(dict(fips=state, state=STATES[state], metric=metric, boundary_year=year,
                    observed_log_pp=rates[year], local_median_log_pp=center, local_intervals=len(neighbors),
                    mad_log_pp=mad, robust_scale_log_pp=scale, deviation_log_pp=residual,
                    robust_score=residual/scale, unusual=flag, old_release_boundary_population=old,
                    old_release_growth_log_pp=within, same_year_revision_log_pp=revision,
                    interpretation=interpretation))
    return annual, diagnostic


def write_csv(path, rows):
    with path.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)


def heatmap(path, rows):
    # Diverging colors, fixed common scale; numeric labels retain values outside saturation.
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1160" height="1590" viewBox="0 0 1160 1590">',
           '<rect width="100%" height="100%" fill="white"/>',
           '<g font-family="Arial, sans-serif" fill="#172b4d">',
           '<text x="30" y="36" font-size="26">Population changes at Census vintage boundaries</text>',
           '<text x="30" y="66" font-size="17">Annual log percentage points. Blue = decline; red = increase. * = unusual versus local trend.</text>',
           '<text x="30" y="92" font-size="17">Color saturates at ±3 points; flags are screening rules, not proof of a methodological break.</text>']
    lookup={(r['fips'],r['metric'],r['boundary_year']):r for r in rows}
    columns=[(m,y) for m in ('total','working_age') for y in BOUNDARIES]
    for j,(metric,year) in enumerate(columns):
        svg.append(f'<text x="{240+j*148}" y="130" font-size="16">{year-1}/{str(year)[2:]}</text>')
        svg.append(f'<text x="{240+j*148}" y="152" font-size="14">{"Total" if metric=="total" else "Ages 15–64"}</text>')
    for i,(state,name) in enumerate(STATES.items()):
        y=170+i*28
        svg.append(f'<text x="25" y="{y+19}" font-size="16">{escape(name)}</text>')
        for j,(metric,year) in enumerate(columns):
            r=lookup[state,metric,year]; value=r['observed_log_pp']; a=min(abs(value)/3,1)
            target=(204,78,65) if value>=0 else (64,126,181)
            color='#'+''.join(f'{round(255*(1-a)+v*a):02x}' for v in target)
            x=230+j*148
            svg.append(f'<rect x="{x}" y="{y}" width="142" height="26" fill="{color}"/>')
            label=f'{value:+.2f}'+('*' if r['unusual'] else '')
            svg.append(f'<text x="{x+40}" y="{y+19}" font-size="16" fill="black">{label}</text>')
    svg.append('</g></svg>'); path.write_text('\n'.join(svg))


def overlap_plot(path, rows):
    svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1180" height="820" viewBox="0 0 1180 820">',
         '<rect width="100%" height="100%" fill="white"/><g font-family="Arial, sans-serif" fill="#172b4d">',
         '<text x="25" y="35" font-size="25">How much of the boundary change is a release revision?</text>',
         '<text x="25" y="63" font-size="16">Each dot is a state. Same-year revisions compare July 1 counts; they are not annual demographic growth.</text>']
    for j,(metric,year) in enumerate([(m,y) for y in (2010,2020) for m in ('total','working_age')]):
        subset=[r for r in rows if r['metric']==metric and r['boundary_year']==year]
        x0=95+(j%2)*575; y0=130+(j//2)*345; width=440; height=235
        limit=max(1, math.ceil(max(max(abs(r['observed_log_pp']),abs(r['same_year_revision_log_pp'])) for r in subset)))
        sx=lambda x: x0+(x/limit+1)*width/2
        sy=lambda y: y0+(1-y/limit)*height/2
        svg.append(f'<text x="{x0}" y="{y0-20}" font-size="20">{year}: {"Total population" if metric=="total" else "Ages 15–64"}</text>')
        for tick in (-limit,0,limit):
            svg.append(f'<path d="M {sx(tick)} {y0} V {y0+height} M {x0} {sy(tick)} H {x0+width}" stroke="#ccd2da" fill="none"/>')
            svg.append(f'<text x="{sx(tick)-12}" y="{y0+height+20}" font-size="13">{tick:+}</text>')
            svg.append(f'<text x="{x0-38}" y="{sy(tick)+5}" font-size="13">{tick:+}</text>')
        svg.append(f'<text x="{x0+85}" y="{y0+height+43}" font-size="15">Observed annual change (log pp)</text>')
        svg.append(f'<text transform="translate({x0-52},{y0+height-10}) rotate(-90)" font-size="15">Same-year revision (log pp)</text>')
        top=sorted(subset,key=lambda r:abs(r['same_year_revision_log_pp']),reverse=True)[:3]
        for r in subset:
            x=sx(r['observed_log_pp']); y=sy(r['same_year_revision_log_pp'])
            svg.append(f'<circle cx="{x}" cy="{y}" r="4" fill="#2166ac" opacity="0.75"><title>{escape(r["state"])}</title></circle>')
            if r in top:
                label_y=y0+20+top.index(r)*22
                label_x=x0+12
                svg.append(f'<path d="M {label_x+130} {label_y-4} L {x} {y}" stroke="#8b99aa" fill="none"/>')
                svg.append(f'<text x="{label_x}" y="{label_y}" font-size="12">{escape(r["state"])}</text>')
    svg.append('</g></svg>'); path.write_text('\n'.join(svg))


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('source_dir',type=Path)
    ap.add_argument('--output',type=Path,default=Path('reports/census_boundaries'))
    args=ap.parse_args(); args.output.mkdir(parents=True,exist_ok=True)
    pop,working,overlaps,manifest={},{},{},[]
    for index,(relative,kind,years) in enumerate(SOURCES):
        file=args.source_dir/Path(relative).name
        p,w=audit(file,kind,years,return_population=True)
        if pop.keys() & p.keys(): raise ValueError('Overlapping analysis years')
        pop.update(p); working.update(w)
        if index in (3,4):
            year=2010 if index==3 else 2020
            oldp,oldw=audit(file,kind,[year],return_population=True)
            for metric,old in [('total',oldp),('working_age',oldw)]:
                overlaps.update({(metric,s,y):v for (s,y),v in old.items()})
        manifest.append(dict(file=file.name,url=BASE+relative,sha256=hashlib.sha256(file.read_bytes()).hexdigest(),
                             analysis_years=years,overlap_year=2010 if index==3 else 2020 if index==4 else None))
    annual,diagnostic=diagnose(pop,working,overlaps)
    panel=[dict(fips=s,state=STATES[s],year=y,total=pop[s,y],working_age=working[s,y]) for s,y in sorted(pop)]
    write_csv(args.output/'population_panel.csv',panel)
    write_csv(args.output/'annual_changes.csv',annual)
    write_csv(args.output/'boundary_diagnostics.csv',diagnostic)
    summary=[]
    for year in BOUNDARIES:
        for metric in ('total','working_age'):
            r=[d for d in diagnostic if d['boundary_year']==year and d['metric']==metric]
            revisions=[d['same_year_revision_log_pp'] for d in r if d['same_year_revision_log_pp'] is not None]
            summary.append(dict(year=year,metric=metric,unusual_states=sum(d['unusual'] for d in r),
                min_log_pp=min(d['observed_log_pp'] for d in r),max_log_pp=max(d['observed_log_pp'] for d in r),
                material_revision_states=sum(abs(v)>=0.5 for v in revisions) if revisions else None))
    write_csv(args.output/'boundary_summary.csv',summary)
    (args.output/'source_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    heatmap(args.output/'boundary_heatmap.svg',diagnostic)
    overlap_plot(args.output/'overlap_revisions.svg',diagnostic)
    print(json.dumps(summary,indent=2))

if __name__=='__main__': main()
