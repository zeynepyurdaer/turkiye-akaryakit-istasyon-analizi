-- 03_master_table.sql
-- Amaç:
-- İstasyon verisini il seviyesinde özetlemek
-- ve nüfus, taşıt, turizm, yüzölçümü ve karayolu verileriyle birleştirmek.

-- 1) İl bazında istasyon özeti
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.il_ozet` AS
SELECT
  il,
  COUNT(*) AS toplam_istasyon,
  COUNTIF(has_lpg = TRUE) AS lpgli_istasyon,
  COUNTIF(has_charge = TRUE) AS sarjli_istasyon,
  SAFE_DIVIDE(COUNTIF(has_lpg = TRUE), COUNT(*)) * 100 AS lpg_orani,
  SAFE_DIVIDE(COUNTIF(has_charge = TRUE), COUNT(*)) * 100 AS sarj_orani,
  COUNT(DISTINCT brand) AS marka_sayisi
FROM
  `akaryakit-final-projesi-483921.analytics.istasyonlar_il_final`
GROUP BY
  il;

-- 2) İl isimleri için standart join anahtarı
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.il_nufus_analiz` AS
SELECT
  i.*,
  n.nufus_2025,
  SAFE_DIVIDE(i.toplam_istasyon, n.nufus_2025) * 100000
    AS yuz_bin_kisi_basina_istasyon
FROM (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.analytics.il_ozet`
) AS i
LEFT JOIN (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.raw_data.nufus_2025`
) AS n
USING (il_key);

-- 3) Motorlu taşıt verisini ekle
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.il_master_analiz` AS
SELECT
  a.* EXCEPT(il_key),
  t.tasit_2025,
  SAFE_DIVIDE(a.toplam_istasyon, t.tasit_2025) * 10000
    AS on_bin_tasit_basina_istasyon
FROM (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.analytics.il_nufus_analiz`
) AS a
LEFT JOIN (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.raw_data.tasit_2025`
) AS t
USING (il_key);

-- 4) Turizm verisini ekle
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.final_master` AS
SELECT
  a.* EXCEPT(il_key),
  tr.geceleme_2025,
  SAFE_DIVIDE(a.toplam_istasyon, tr.geceleme_2025) * 1000000
    AS bir_milyon_geceleme_basina_istasyon
FROM (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.analytics.il_master_analiz`
) AS a
LEFT JOIN (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.raw_data.turizm_2025`
) AS tr
USING (il_key);

-- 5) İl yüzölçümünü coğrafi polygonlardan hesapla
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.il_yuzolcumu` AS
SELECT
  shapeName AS il,
  ROUND(ST_AREA(geometry) / 1000000, 2) AS yuzolcumu_km2
FROM
  `akaryakit-final-projesi-483921.raw_data.il_sinirlari`;

-- 6) Yüzölçümünü ekle
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.final_master_v2` AS
SELECT
  a.* EXCEPT(il_key),
  y.yuzolcumu_km2,
  SAFE_DIVIDE(a.toplam_istasyon, y.yuzolcumu_km2) * 1000
    AS bin_km2_basina_istasyon
FROM (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.analytics.final_master`
) AS a
LEFT JOIN (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.analytics.il_yuzolcumu`
) AS y
USING (il_key);

-- 7) Karayolu verisini ekle ve final master tabloyu oluştur
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.final_master_v3` AS
SELECT
  a.* EXCEPT(il_key),
  k.karayolu_km,
  k.bolunmus_yol_km,
  k.asfalt_yol_km,
  SAFE_DIVIDE(a.toplam_istasyon, k.karayolu_km) * 100
    AS yuz_km_yol_basina_istasyon,
  SAFE_DIVIDE(a.lpgli_istasyon, k.karayolu_km) * 100
    AS yuz_km_yol_basina_lpgli_istasyon,
  SAFE_DIVIDE(a.sarjli_istasyon, k.karayolu_km) * 100
    AS yuz_km_yol_basina_sarjli_istasyon
FROM (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.analytics.final_master_v2`
) AS a
LEFT JOIN (
  SELECT
    *,
    REGEXP_REPLACE(
      REPLACE(LOWER(NORMALIZE(TRIM(il), NFD)), 'ı', 'i'),
      r'\pM',
      ''
    ) AS il_key
  FROM
    `akaryakit-final-projesi-483921.raw_data.karayolu_2025`
) AS k
USING (il_key);
