-- 05_regression_model.sql
-- Amaç: Motorlu taşıt, turizm ve karayolu verilerini birlikte kullanarak
-- il bazındaki istasyon sayısı için açıklayıcı regresyon modeli oluşturmak.

-- Ham doğrusal model
CREATE OR REPLACE MODEL
  `akaryakit-final-projesi-483921.analytics.istasyon_regresyon_v1`
OPTIONS(
  MODEL_TYPE = 'LINEAR_REG',
  INPUT_LABEL_COLS = ['toplam_istasyon']
) AS
SELECT
  toplam_istasyon,
  tasit_2025,
  geceleme_2025,
  karayolu_km
FROM
  `akaryakit-final-projesi-483921.analytics.final_master_v3`;

-- Ham modeli değerlendir
SELECT *
FROM ML.EVALUATE(
  MODEL `akaryakit-final-projesi-483921.analytics.istasyon_regresyon_v1`
);

-- Log-log model
CREATE OR REPLACE MODEL
  `akaryakit-final-projesi-483921.analytics.istasyon_regresyon_log_v2`
OPTIONS(
  MODEL_TYPE = 'LINEAR_REG',
  INPUT_LABEL_COLS = ['log_istasyon']
) AS
SELECT
  LN(toplam_istasyon) AS log_istasyon,
  LN(tasit_2025) AS log_tasit,
  LN(geceleme_2025) AS log_turizm,
  LN(karayolu_km) AS log_karayolu
FROM
  `akaryakit-final-projesi-483921.analytics.final_master_v3`;

-- Final model tahminleri
CREATE OR REPLACE TABLE
  `akaryakit-final-projesi-483921.analytics.il_final_model_sonuclari` AS
SELECT
  il,
  toplam_istasyon AS gercek_istasyon,
  EXP(predicted_log_istasyon) AS tahmini_istasyon,
  toplam_istasyon - EXP(predicted_log_istasyon) AS fark,
  ABS(toplam_istasyon - EXP(predicted_log_istasyon)) AS mutlak_hata,
  SAFE_DIVIDE(
    toplam_istasyon - EXP(predicted_log_istasyon),
    EXP(predicted_log_istasyon)
  ) * 100 AS tahmine_gore_sapma_yuzde,

  CASE
    WHEN SAFE_DIVIDE(
      toplam_istasyon - EXP(predicted_log_istasyon),
      EXP(predicted_log_istasyon)
    ) * 100 < -20
      THEN 'Beklentinin belirgin altında'

    WHEN SAFE_DIVIDE(
      toplam_istasyon - EXP(predicted_log_istasyon),
      EXP(predicted_log_istasyon)
    ) * 100 > 20
      THEN 'Beklentinin belirgin üstünde'

    ELSE 'Beklentiye yakın'
  END AS model_profili

FROM ML.PREDICT(
  MODEL `akaryakit-final-projesi-483921.analytics.istasyon_regresyon_log_v2`,
  (
    SELECT
      il,
      toplam_istasyon,
      LN(tasit_2025) AS log_tasit,
      LN(geceleme_2025) AS log_turizm,
      LN(karayolu_km) AS log_karayolu
    FROM
      `akaryakit-final-projesi-483921.analytics.final_master_v3`
  )
);
