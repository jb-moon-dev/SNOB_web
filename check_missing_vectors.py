import json

# 파일 불러오기
with open(
    'assets/data/snob_concentration.json',
    encoding='utf-8'
) as f:
    concentration = json.load(f)

with open(
    'assets/data/region_vectors_canonical.json',
    encoding='utf-8'
) as f:
    vectors = json.load(f)


# canonical 210 지역
canonical = {
    f"{x['sido'].strip()} {x['sigungu'].strip()}"
    for x in concentration['records']
    if x.get('sido') and x.get('sigungu')
}

# 현재 정리된 RegionVector 지역
vector_regions = {
    x['regionName'].strip()
    for x in vectors
}


# 누락 지역
missing = sorted(canonical - vector_regions)


print()
print("=" * 70)
print("🔍 canonical 210 중 RegionVector 점수가 없는 지역")
print("=" * 70)

for region in missing:
    print(region)

print()
print("=" * 70)
print("📊 결과")
print("=" * 70)
print(f"canonical 지역 수 : {len(canonical)}")
print(f"RegionVector 수   : {len(vector_regions)}")
print(f"점수 없는 지역    : {len(missing)}")
print("=" * 70)
