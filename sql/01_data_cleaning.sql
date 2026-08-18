-- 01_data_cleaning.sql
-- Amaç:
-- Ham akaryakıt istasyonu verisinin temel kalite kontrollerini yapmak
-- ve analiz için temiz bir istasyon tablosu oluşturmak.

-- 1) Toplam kayıt ve benzersiz ID kontrolü
SELECT
  COUNT(*) AS toplam_kayit,
  COUNT(DISTINCT id) AS benzersiz_id
FROM `akaryakit-final-projesi-483921.raw_data.istasyonlar`;

-- 2) Eksik değer kontrolleri
SELECT
  COUNTIF(istasyon_adi IS NULL) AS eksik_istasyon_adi,
  COUNTIF(lat IS NULL) AS eksik_lat,
  COUNTIF(lon IS NULL) AS eksik_lon,
  COUNTIF(brand IS NULL) AS eksik_brand
FROM `akaryakit-final-projesi-483921.raw_data.istasyonlar`;

-- 3) Temizlenmiş istasyon tablosu
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.clean_istasyonlar` AS
SELECT
  id,
  TRIM(istasyon_adi) AS istasyon_adi,
  lat,
  lon,
  TRIM(brand) AS brand,
  has_lpg,
  has_charge
FROM `akaryakit-final-projesi-483921.raw_data.istasyonlar`
WHERE
  lat IS NOT NULL
  AND lon IS NOT NULL;
