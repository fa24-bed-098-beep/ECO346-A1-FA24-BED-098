"""04_second_language.py -- Question 5: band table and figure in Python. Run from the repo root."""
import os
import numpy as np, pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

PROV, AREA = 3, 1                     # variant 2 = Sindh rural
os.makedirs("figures", exist_ok=True); os.makedirs("tables", exist_ok=True)
p = pd.read_csv("data/pslm_person_subset.csv")
h = pd.read_csv("data/pslm_hh_subset.csv", usecols=["hhid", "hhweight", "prov_code", "urban_rural"])
d = p.merge(h, on="hhid", how="inner")
d = d[(d.prov_code == PROV) & (d.urban_rural == AREA)]

lit = d[d.age.between(10, 64) & d.literate.notna()].copy()
lit["start"] = 5 * (lit.age // 5)          # explicit left-closed bands: 10-14, 15-19, ...
lit["mid"] = lit.start + 2
lit["band"] = lit.start.astype(int).astype(str) + "-" + (lit.start + 4).astype(int).astype(str)
lit["sex_lab"] = lit.sex.map({1: "Men", 2: "Women"})

def cell(g):
    return pd.Series({"n": len(g), "rate": 100 * np.average(g.literate, weights=g.hhweight)})
tab = lit.groupby(["mid", "band", "sex_lab"]).apply(cell, include_groups=False).reset_index()
tab["thin"] = tab.n < 30
tab.to_csv("tables/band_table_py.csv", index=False)
print(tab.pivot(index="band", columns="sex_lab", values=["n", "rate"]).round(1))
w1519 = tab[(tab.band == "15-19") & (tab.sex_lab == "Women")].rate.iloc[0]
print(f"Women 15-19 (Python): {w1519:.1f}")

# compare with R's table if it exists
if os.path.exists("tables/band_table_R.csv"):
    r = pd.read_csv("tables/band_table_R.csv")
    m = tab.merge(r, on=["mid", "sex_lab"], suffixes=("_py", "_R"))
    print("Max abs difference vs R (percentage points):", (m.rate_py - m.rate_R).abs().max())
    print("Tables agree to one decimal:", bool((m.rate_py.round(1) == m.rate_R.round(1)).all()))

wide = tab.pivot(index="mid", columns="sex_lab", values="rate")
gap = (wide.Men - wide.Women); gm = gap.abs().idxmax()
cols = {"Women": "#C0392B", "Men": "#1F5A99"}
fig, ax = plt.subplots(figsize=(9, 5.5))
for s, c in cols.items():
    t = tab[tab.sex_lab == s]
    ax.plot(t.mid, t.rate, color=c, lw=1.8)
    ax.scatter(t.mid, t.rate, s=45, facecolors=[("white" if th else c) for th in t.thin], edgecolors=c, linewidths=1.5, zorder=3)
    ax.text(t.mid.max() + 0.8, t.rate.iloc[-1], s, color=c, fontweight="bold", va="center")
ax.plot([gm, gm], [wide.loc[gm, "Women"], wide.loc[gm, "Men"]], "k:", lw=1)
ax.text(gm + 1, (wide.loc[gm, "Women"] + wide.loc[gm, "Men"]) / 2,
        f"Largest gap: {gap[gm]:.1f} points\n(ages {int(gm-2)}-{int(gm+2)})", va="center")
ax.set_ylim(0, 100); ax.set_xticks(range(12, 63, 5)); ax.set_xlim(10, 68)
ax.yaxis.set_major_formatter(lambda v, _: f"{v:.0f}%")
for sp in ("top", "right"): ax.spines[sp].set_visible(False)
ax.set_xlabel("Age band (plotted at midpoint, years)"); ax.set_ylabel("Literate (weighted share)")
ax.set_title(f"In rural Sindh men are more literate than women at every age, by up to {gap.abs().max():.1f} points",
             loc="left", fontweight="bold", fontsize=11)
fig.text(0.01, 0.01, f"Source: PSLM 2019-20. Sample: persons aged 10-64 in rural Sindh (n = {len(lit):,}). Weighted by hhweight. "
         "Hollow markers: fewer than 30 observations.", fontsize=7, ha="left")
fig.tight_layout(rect=(0, 0.03, 1, 1))
plt.savefig("figures/literacy_by_age_python.svg")
