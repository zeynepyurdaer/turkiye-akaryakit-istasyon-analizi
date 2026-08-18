-- 02_spatial_join.sql
-- Amaç:
-- İstasyon koordinatlarını coğrafi noktaya çevirmek,
-- il sınırlarıyla spatial join yapmak
-- ve eşleşmeyen kayıtları en yakın il sınırına göre kontrol etmek.

-- 1) İstasyon koordinatlarını GEOGRAPHY noktaya çevir
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.istasyonlar_geo` AS
SELECT
  *,
  ST_GEOGPOINT(lon, lat) AS konum
FROM
  `akaryakit-final-projesi-483921.analytics.clean_istasyonlar`;

-- 2) İstasyonları doğrudan içinde bulundukları illerle eşleştir
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.istasyonlar_il` AS
SELECT
  i.*,
  s.shapeName AS il
FROM
  `akaryakit-final-projesi-483921.analytics.istasyonlar_geo` AS i
JOIN
  `akaryakit-final-projesi-483921.raw_data.il_sinirlari` AS s
ON
  ST_CONTAINS(s.geometry, i.konum);

-- 3) Doğrudan eşleşmeyen istasyonları bul
WITH eslesen_idler AS (
  SELECT DISTINCT id
  FROM `akaryakit-final-projesi-483921.analytics.istasyonlar_il`
)
SELECT
  *
FROM
  `akaryakit-final-projesi-483921.analytics.istasyonlar_geo`
WHERE
  id NOT IN (SELECT id FROM eslesen_idler);

-- 4) Eşleşmeyen kayıtların en yakın il sınırına uzaklığını kontrol et
WITH eslesen_idler AS (
  SELECT DISTINCT id
  FROM `akaryakit-final-projesi-483921.analytics.istasyonlar_il`
),
eslesmeyenler AS (
  SELECT
    *
  FROM
    `akaryakit-final-projesi-483921.analytics.istasyonlar_geo`
  WHERE
    id NOT IN (SELECT id FROM eslesen_idler)
)
SELECT
  e.id,
  e.istasyon_adi,
  s.shapeName AS en_yakin_il,
  ST_DISTANCE(e.konum, s.geometry) AS mesafe_metre
FROM
  eslesmeyenler AS e
CROSS JOIN
  `akaryakit-final-projesi-483921.raw_data.il_sinirlari` AS s
QUALIFY
  ROW_NUMBER() OVER (
    PARTITION BY e.id
    ORDER BY ST_DISTANCE(e.konum, s.geometry)
  ) = 1
ORDER BY
  mesafe_metre;

-- 5) Final il eşleştirme tablosu
-- Kural:
-- - İl sınırı içinde olanlar doğrudan kabul edilir
-- - Doğrudan eşleşmeyen ancak en yakın il sınırına <= 100 metre olanlar kabul edilir
-- - 100 metreden uzak kayıtlar il bazlı analiz dışında bırakılır

CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.istasyonlar_il_final` AS

WITH direct_match AS (
  SELECT
    i.*,
    s.shapeName AS il
  FROM
    `akaryakit-final-projesi-483921.analytics.istasyonlar_geo` AS i
  JOIN
    `akaryakit-final-projesi-483921.raw_data.il_sinirlari` AS s
  ON
    ST_CONTAINS(s.geometry, i.konum)
),

matched_ids AS (
  SELECT DISTINCT id
  FROM direct_match
),

unmatched AS (
  SELECT
    *
  FROM
    `akaryakit-final-projesi-483921.analytics.istasyonlar_geo`
  WHERE
    id NOT IN (SELECT id FROM matched_ids)
),

nearest_province AS (
  SELECT
    u.*,
    s.shapeName AS il,
    ST_DISTANCE(u.konum, s.geometry) AS mesafe_metre
  FROM
    unmatched AS u
  CROSS JOIN
    `akaryakit-final-projesi-483921.raw_data.il_sinirlari` AS s
  QUALIFY
    ROW_NUMBER() OVER (
      PARTITION BY u.id
      ORDER BY ST_DISTANCE(u.konum, s.geometry)
    ) = 1
)

SELECT
  *,
  0 AS mesafe_metre
FROM direct_match

UNION ALL

SELECT
  *
FROM nearest_province
WHERE mesafe_metre <= 100;
