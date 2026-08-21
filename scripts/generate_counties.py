import json, os, time, urllib.parse, urllib.request

BASE = "https://bdl.stat.gov.pl/api/v1"
KEY = os.environ["BDL_API_KEY"]
CITY_CODE_MIN = 61


def get(path, **params):
    params["format"] = "json"
    url = f"{BASE}/{path}?" + urllib.parse.urlencode(params, doseq=True)
    req = urllib.request.Request(url, headers={"X-ClientId": KEY})
    with urllib.request.urlopen(req) as r:
        data = json.load(r)
    time.sleep(0.25)
    return data


def q(value):
    if value is None:
        return "NULL"
    return "N'" + str(value).replace("'", "''") + "'"


voivodeships = {
    u["id"][2:4]: u["name"].capitalize()
    for u in get("units", level=2, **{"page-size": 100})["results"]
}

subregions = {}
page = 0
while True:
    data = get("units", level=4, **{"page-size": 100, "page": page})
    for u in data["results"]:
        subregions[u["id"][:7]] = u["name"].capitalize()
    if not data["links"].get("next"):
        break
    page += 1

units = []
page = 0
while True:
    data = get("units", level=5, **{"page-size": 100, "page": page})
    units.extend(data["results"])
    if not data["links"].get("next"):
        break
    page += 1

rows = []
for u in units:
    teryt = u["id"]
    name = u["name"]
    voiv = voivodeships.get(teryt[2:4])
    subregion_code = teryt[:7]
    subregion_name = subregions.get(subregion_code)
    is_city = int(teryt[7:9]) >= CITY_CODE_MIN
    county_type = "city" if is_city else "rural"
    rows.append((teryt, name, voiv, subregion_code, subregion_name, county_type))

os.makedirs("sql/03_seed", exist_ok=True)

values = ",\n".join(
    f"  ({q(t)}, {q(n)}, {q(v)}, {q(sc)}, {q(sn)}, {q(ct)})"
    for t, n, v, sc, sn, ct in rows
)

with open("sql/03_seed/04_county_classification.sql", "w", encoding="utf-8") as f:
    f.write(f"""MERGE ref.county_classification AS t
USING (VALUES
{values}
) AS s (teryt_code, name, voivodeship, subregion_code, subregion_name, county_type)
ON t.teryt_code = s.teryt_code
WHEN MATCHED THEN UPDATE SET
    t.name = s.name,
    t.voivodeship = s.voivodeship,
    t.subregion_code = s.subregion_code,
    t.subregion_name = s.subregion_name,
    t.county_type = s.county_type
WHEN NOT MATCHED THEN INSERT
    (teryt_code, name, voivodeship, subregion_code, subregion_name, county_type)
    VALUES (s.teryt_code, s.name, s.voivodeship, s.subregion_code,
            s.subregion_name, s.county_type);
""")

cities = sum(1 for r in rows if r[5] == "city")
print(f"counties: {len(rows)}, cities: {cities}, rural: {len(rows) - cities}, subregions: {len(subregions)}")
