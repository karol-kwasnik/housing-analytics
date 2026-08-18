import json, os, time, urllib.parse, urllib.request

BASE = "https://bdl.stat.gov.pl/api/v1"
KEY = os.environ["BDL_API_KEY"]
UNIT_LEVEL = 5
YEAR_MIN = 2010

PRICE_SUBJECTS = {
    "P3787": ("prices", "median_price_sqm"),
    "P3788": ("prices", "avg_price_sqm"),
    "P3783": ("transactions", "dwellings_sold"),
    "P3785": ("transactions", "floor_area_sold"),
    "P3786": ("prices", "avg_dwelling_price"),
}

CONTEXT = {
    64428:  ("income", "avg_gross_salary"),
    72305:  ("demography", "population"),
    748601: ("supply", "dwellings_completed"),
    748603: ("supply", "floor_area_completed"),
    410600: ("housing_stock", "dwellings_per_1000"),
    475703: ("housing_stock", "persons_per_dwelling"),
    60573:  ("housing_stock", "floor_area_per_person"),
}

REAL_ZERO_ATTRIBUTES = {94, 98}


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


subjects = {}


def subject(sid):
    if sid not in subjects:
        s = get(f"subjects/{sid}")
        subjects[sid] = (s["name"], s.get("years") or [])
    return subjects[sid]


variables = []


def collect(v, category, measure):
    name, years = subject(v["subjectId"])
    full_name = " - ".join(p for p in [name, v.get("n1"), v.get("n2")] if p)[:400]
    variables.append({
        "id": v["id"],
        "name": full_name,
        "subject_id": v["subjectId"],
        "category": category,
        "measure": measure,
        "unit": v.get("measureUnitName"),
        "d1": v.get("n1"),
        "d2": v.get("n2"),
        "year_from": max(YEAR_MIN, min(years)) if years else None,
        "year_to": max(years) if years else None,
    })


for sid, (category, measure) in PRICE_SUBJECTS.items():
    for v in get("variables", **{"subject-id": sid, "page-size": 100})["results"]:
        collect(v, category, measure)

for vid, (category, measure) in CONTEXT.items():
    collect(get(f"variables/{vid}"), category, measure)

os.makedirs("sql/03_seed", exist_ok=True)

rows = ",\n".join(
    f"  ({v['id']}, {q(v['name'])}, {q(v['subject_id'])}, {q(v['category'])}, "
    f"{q(v['measure'])}, {q(v['unit'])}, {UNIT_LEVEL}, {q(v['d1'])}, {q(v['d2'])})"
    for v in variables
)

with open("sql/03_seed/01_variable.sql", "w", encoding="utf-8") as f:
    f.write(f"""MERGE ref.variable AS t
USING (VALUES
{rows}
) AS s (variable_id, name, subject_id, category, measure, unit_of_measure, unit_level, dimension_1, dimension_2)
ON t.variable_id = s.variable_id
WHEN MATCHED THEN UPDATE SET
    t.name = s.name, t.subject_id = s.subject_id, t.category = s.category,
    t.measure = s.measure, t.unit_of_measure = s.unit_of_measure,
    t.unit_level = s.unit_level, t.dimension_1 = s.dimension_1,
    t.dimension_2 = s.dimension_2, t.modified_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT
    (variable_id, name, subject_id, category, measure, unit_of_measure, unit_level, dimension_1, dimension_2)
    VALUES (s.variable_id, s.name, s.subject_id, s.category, s.measure,
            s.unit_of_measure, s.unit_level, s.dimension_1, s.dimension_2);
""")

config_rows = ",\n".join(
    f"  ({v['id']}, {UNIT_LEVEL}, {v['year_from']}, {v['year_to']})"
    for v in variables if v["year_from"]
)

with open("sql/03_seed/02_ingestion_config.sql", "w", encoding="utf-8") as f:
    f.write(f"""MERGE ref.ingestion_config AS t
USING (VALUES
{config_rows}
) AS s (variable_id, unit_level, year_from, year_to)
ON t.variable_id = s.variable_id AND t.unit_level = s.unit_level
WHEN MATCHED THEN UPDATE SET t.year_from = s.year_from, t.year_to = s.year_to
WHEN NOT MATCHED THEN INSERT (variable_id, unit_level, year_from, year_to)
    VALUES (s.variable_id, s.unit_level, s.year_from, s.year_to);
""")

attrs = get("attributes", **{"page-size": 100})["results"]
attr_rows = ",\n".join(
    f"  ({a['id']}, {q(a['name'])}, {q(a['symbol'])}, {q(a['description'])}, "
    f"{1 if a['name'] == 'wartość' or a['id'] in REAL_ZERO_ATTRIBUTES else 0})"
    for a in attrs
)

with open("sql/03_seed/03_quality_attribute.sql", "w", encoding="utf-8") as f:
    f.write(f"""MERGE ref.quality_attribute AS t
USING (VALUES
{attr_rows}
) AS s (attribute_id, name, symbol, description, is_value)
ON t.attribute_id = s.attribute_id
WHEN MATCHED THEN UPDATE SET
    t.name = s.name, t.symbol = s.symbol, t.description = s.description, t.is_value = s.is_value
WHEN NOT MATCHED THEN INSERT (attribute_id, name, symbol, description, is_value)
    VALUES (s.attribute_id, s.name, s.symbol, s.description, s.is_value);
""")

print(f"variables: {len(variables)}, attributes: {len(attrs)}")
