-- 04_correlation_analysis.sql
-- Amaç: İstasyon sayısının temel değişkenlerle ilişkisini ölçmek
-- ve bağımsız değişkenlerin kendi aralarındaki yüksek korelasyonları kontrol etmek.

SELECT
  CORR(toplam_istasyon, tasit_2025) AS corr_istasyon_tasit,
  CORR(toplam_istasyon, nufus_2025) AS corr_istasyon_nufus,
  CORR(toplam_istasyon, geceleme_2025) AS corr_istasyon_turizm,
  CORR(toplam_istasyon, yuzolcumu_km2) AS corr_istasyon_yuzolcumu,
  CORR(toplam_istasyon, karayolu_km) AS corr_istasyon_karayolu
FROM `akaryakit-final-projesi-483921.analytics.final_master_v3`;

SELECT
  CORR(nufus_2025, tasit_2025) AS corr_nufus_tasit,
  CORR(yuzolcumu_km2, karayolu_km) AS corr_yuzolcumu_karayolu,
  CORR(tasit_2025, geceleme_2025) AS corr_tasit_turizm,
  CORR(tasit_2025, karayolu_km) AS corr_tasit_karayolu,
  CORR(geceleme_2025, karayolu_km) AS corr_turizm_karayolu
FROM `akaryakit-final-projesi-483921.analytics.final_master_v3`;
