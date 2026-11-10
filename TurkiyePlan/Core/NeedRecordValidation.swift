import Foundation
nonisolated struct NeedRecordValidation {
 func issues(_ r: NeedRecord, priceYear: Int) -> [String] {
  var result: [String] = []
  if r.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { result.append("Kaynak / veri seti / yöntem alanını doldurun. Nüfus kaynağı tek başına hizmet ihtiyacını ve maliyetini doğrulamaz.") }
  if r.referenceYear != priceYear { result.append("Maliyetlerin fiyat yılı " + String(r.referenceYear) + "; planın fiyat yılı " + String(priceYear) + ". Fiyat bazlarını uyumlu hale getirin. Nüfus gözleminin yılı farklı olabilir.") }
  if r.population < 0 { result.append("Nüfus negatif olamaz.") }
  if r.eligible < 0 || r.eligible > r.population { result.append("Hizmete ihtiyaç duyan kişi sayısı 0 ile nüfus arasında olmalı.") }
  if r.served < 0 || r.served > r.eligible { result.append("Yeterli hizmet alan sayısı 0 ile ihtiyaç duyan kişi sayısı arasında olmalı.") }
  if !r.targetCoverage.isFinite || !(0...1).contains(r.targetCoverage) { result.append("Hedef kapsam 0 ile 1 arasında olmalı.") }
  if let rate = r.povertyRate, !rate.isFinite || !(0...1).contains(rate) { result.append("Yoksulluk oranı 0 ile 1 arasında olmalı.") }
  if !r.deliveryCostIndex.isFinite || r.deliveryCostIndex <= 0 { result.append("Hizmet maliyeti endeksi sıfırdan büyük olmalı.") }
  if !r.fiscalCapacityIndex.isFinite || r.fiscalCapacityIndex <= 0 { result.append("Mali kapasite endeksi sıfırdan büyük olmalı.") }
  if r.capitalUnitCents < 0 { result.append("Birim yatırım maliyeti negatif olamaz.") }
  if r.annualUnitCents < 0 { result.append("Birim yıllık işletme maliyeti negatif olamaz.") }
  if !(1...50).contains(r.horizonYears) { result.append("İşletme süresi 1 ile 50 yıl arasında olmalı.") }
  if !r.requirementCents.isFinite || r.requirementCents > 9_000_000_000_000_000 { result.append("Hesaplanan gereksinim desteklenen sayısal sınırı aşıyor.") }
  return result
 }
}
