from pathlib import Path
import json, copy
root = Path(__file__).resolve().parent.parent
resources = root / "TurkiyePlan" / "Resources"
def read(name): return json.loads((resources / name).read_text())
def write(name, value): (resources / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
source = read("finance-source-2025.json")
figures = source["figures"]
scale = source["moneyScaleToCents"]
revenue = figures["revenueMillionTRY"] * scale
non_interest = figures["nonInterestSpendingMillionTRY"] * scale
interest = figures["interestSpendingMillionTRY"] * scale
assert non_interest + interest == figures["totalSpendingMillionTRY"] * scale
assert non_interest + interest - revenue == figures["deficitMillionTRY"] * scale
presets = read("finance-presets-2025.json")
reported = next(p for p in presets if p["id"] == "reported-2025")
f = reported["finances"]
f.update(ownRevenueCents=revenue, externalTransfersCents=0, committedSpendingCents=non_interest, debtServiceCents=interest, reserveCents=0)
reported["planningBudgetCents"] = max(0, revenue - non_interest - interest)
illustrative = next(p for p in presets if p["id"] == "illustrative-2025")
params = source["whatIfAssumptionsBasisPoints"]
model = illustrative["finances"]
model.update(ownRevenueCents=revenue, externalTransfersCents=0, committedSpendingCents=non_interest * (10000 - params["reallocationOfNonInterestSpending"]) // 10000, debtServiceCents=interest, reserveCents=revenue * params["additionalReserveOfRevenue"] // 10000)
model["provenance"]["assumptions"] = {"reallocationShareOfNonInterestSpending": params["reallocationOfNonInterestSpending"] / 10000, "additionalReserveShareOfRevenue": params["additionalReserveOfRevenue"] / 10000}
illustrative["planningBudgetCents"] = max(0, revenue - model["committedSpendingCents"] - interest - model["reserveCents"])
write("finance-presets-2025.json", presets)
for preset, filename in [(reported, "finance-2025-reported-scenario.json"), (illustrative, "finance-2025-illustrative-scenario.json")]:
    scenario = read(filename)
    scenario["finances"] = copy.deepcopy(preset["finances"])
    scenario["budgetCents"] = preset["planningBudgetCents"]
    write(filename, scenario)
# Keep fresh-install and compatibility seeds aligned with the reported reference.
for filename in ["empty-scenario.json", "demo-scenario.json"]:
    write(filename, read("finance-2025-reported-scenario.json"))
print("Rebuilt finance datasets. Review narrative notes if you changed assumptions or source figures.")
