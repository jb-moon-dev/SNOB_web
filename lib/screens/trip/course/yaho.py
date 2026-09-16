import pandas as pd

excel_file = r"C:\Users\USER\OneDrive\Desktop\SNOB_congestion\output\snob_congestion_nationwide_final.xlsx"
csv_file = r"C:\Users\USER\SNOB\assets\data\tourism_spots_protected.csv"

# =========================
# 1. 혼잡도 지역
# =========================

excel_df = pd.read_excel(
    excel_file,
    sheet_name="최종_관광지_혼잡도"
)

canonical = (
    excel_df[['시도', '시군구']]
    .dropna()
    .drop_duplicates()
)

canonical_names = set(
    canonical['시도'].astype(str).str.strip()
    + ' '
    + canonical['시군구'].astype(str).str.strip()
)

# =========================
# 2. 관광지 지역
# =========================

csv_df = pd.read_csv(
    csv_file,
    encoding='utf-8-sig'
)

tourism_names = set(
    csv_df['regionName']
    .dropna()
    .astype(str)
    .str.strip()
)

# =========================
# 3. 비교
# =========================

only_tourism = sorted(tourism_names - canonical_names)
only_canonical = sorted(canonical_names - tourism_names)

print()
print("=" * 70)
print("관광지 CSV에만 존재하는 지역")
print("=" * 70)

for name in only_tourism:
    print(name)

print()
print(f"총 {len(only_tourism)}개")

print()
print("=" * 70)
print("혼잡도 Excel에만 존재하는 지역")
print("=" * 70)

for name in only_canonical:
    print(name)

print()
print(f"총 {len(only_canonical)}개")