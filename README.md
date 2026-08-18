# Türkiye Akaryakıt İstasyonu Analizi

Türkiye’deki akaryakıt istasyonlarının il bazındaki dağılımını; nüfus, motorlu taşıt sayısı, turizm yoğunluğu, karayolu uzunluğu ve yüzölçümü ile birlikte inceleyen coğrafi ve istatistiksel analiz projesidir.

## Projenin Amacı

Bu çalışmada yalnızca hangi ilde kaç akaryakıt istasyonu olduğu gösterilmemiş; istasyon sayısının farklı talep ve altyapı göstergeleriyle nasıl ilişkili olduğu incelenmiştir.

Temel araştırma sorusu:

> Türkiye’deki akaryakıt istasyonu sayısını nüfus, motorlu taşıt sayısı, turizm yoğunluğu, coğrafi büyüklük ve karayolu altyapısı ne ölçüde açıklamaktadır?

Ayrıca LPG ve elektrikli araç şarj altyapısı da il ve marka bazında incelenmiştir.

## Kullanılan Teknolojiler

- Google BigQuery
- BigQuery GIS
- BigQuery ML
- SQL
- Looker Studio
- Google Cloud Platform

## Veri Hazırlama Süreci

Başlangıç istasyon veri setinde yaklaşık **8.024 kayıt** bulunuyordu. İstasyonlarda doğrudan il bilgisi olmadığı için koordinatlar kullanılarak coğrafi eşleştirme yapıldı.

- İstasyon koordinatları `GEOGRAPHY` noktasına dönüştürüldü.
- İl sınırları ile spatial join gerçekleştirildi.
- 8.019 istasyon doğrudan il sınırı içinde eşleşti.
- İl sınırına çok yakın 1 kayıt en yakın ile atandı.
- Coğrafi olarak güvenilir olmayan 4 kayıt il bazlı analiz dışında bırakıldı.
- Final analizde **8.020 istasyon** kullanıldı.

Farklı veri kaynaklarında il isimlerindeki Türkçe karakter ve Unicode farklılıkları normalize edilerek **81 ilin tamamı** başarıyla eşleştirildi.

## Kullanılan Veri Grupları

- Akaryakıt istasyonu verileri
- 2025 il nüfusları
- 2025 motorlu taşıt sayıları
- 2025 turizm geceleme verileri
- İl sınırı coğrafi verileri
- İl bazında karayolu uzunlukları
- İl yüzölçümü değerleri

## Oluşturulan Göstergeler

İlleri yalnızca toplam istasyon sayısına göre değil, kendi ölçeklerine göre karşılaştırabilmek için aşağıdaki göstergeler oluşturuldu:

- 100.000 kişi başına istasyon
- 10.000 taşıt başına istasyon
- 1.000 km² başına istasyon
- 100 km karayolu başına istasyon

## Temel Analiz Bulguları

İstasyon sayısı ile temel değişkenler arasındaki Pearson korelasyonları yaklaşık olarak:

| Değişken | Korelasyon |
|---|---:|
| Motorlu taşıt sayısı | 0.94 |
| Nüfus | 0.92 |
| Turizm gecelemeleri | 0.53 |
| Yüzölçümü | 0.38 |
| Karayolu uzunluğu | 0.37 |

Motorlu taşıt sayısı, istasyon sayısıyla en güçlü doğrusal ilişkiyi göstermiştir.

> Not: Korelasyon sonuçları nedensellik anlamına gelmez.

## Regresyon Modeli

Bağımsız değişkenler arasındaki yüksek korelasyonlar kontrol edildi. Nüfus ile taşıt sayısı ve yüzölçümü ile karayolu uzunluğu birbirleriyle çok yüksek ilişkili olduğu için ana modelde aynı anda kullanılmadı.

Final modelde:

- Motorlu taşıt sayısı
- Turizm gecelemeleri
- Karayolu uzunluğu

kullanıldı.

BigQuery ML ile oluşturulan log-log regresyon modeli, ham doğrusal modele göre daha düşük ortalama mutlak hata verdi.

| Model | MAE | RMSE |
|---|---:|---:|
| Ham doğrusal model | 21.59 | 28.11 |
| Log-log model | 17.27 | 27.72 |

Model sonuçları kesin bir “istasyon açığı” veya “istasyon fazlası” olarak yorumlanmamıştır. Model beklentisinden belirgin şekilde farklılaşan iller, daha detaylı inceleme için aday bölgeler olarak değerlendirilmiştir.

## LPG ve Şarj Altyapısı

Final coğrafi veri setinde:

- **2.973 LPG’li istasyon**
- **185 şarj hizmeti bulunan istasyon**

bulunmaktadır.

LPG altyapısı mevcut istasyon ağı içinde daha yaygınken, şarj altyapısı daha sınırlı düzeydedir.

## Looker Studio Dashboard

Proje sonuçları 5 sayfalık interaktif Looker Studio dashboard’una aktarılmıştır:

1. Genel Bakış
2. Talep ve Altyapı
3. Model Sonuçları
4. LPG ve Şarj Altyapısı
5. Yoğunluk ve Erişilebilirlik

Dashboard; il bazlı dağılım, temel KPI’lar, scatter plotlar, model tahminleri, LPG/şarj analizi ve normalize edilmiş yoğunluk göstergelerini içermektedir.

## Proje Yapısı

```text
turkiye-akaryakit-istasyon-analizi/
├── README.md
├── sql/
├── dashboard/
└── docs/
