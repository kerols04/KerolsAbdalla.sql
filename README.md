# DB-Lab2 – Bokhandel 

Detta repo innehåller min lösning för **DB-Lab2** där jag bygger en bokhandelsdatabas i **SQL Server (T-SQL)**.

## Innehåll
Lösningen skapar och fyller en databasstruktur med:
- **Minst 8 entitetstabeller** (junction-tabeller räknas ej som entitet)
- **Många-till-många** mellan **Böcker** och **Författare** via junction-tabell
- **Vy**: `v_TitlarPerFörfattare`
- **Stored Procedure**: `usp_FlyttaBok` (transaktion + validering + lagerflytt)
- **Extra vy**: `v_OrdrarPerKund` (aggregering)

## Tabeller (entiteter)
- `Forfattare`
- `Forlag`
- `Kategorier`
- `Bocker`
- `Butiker`
- `Kunder`
- `Ordrar`
- (ev. fler entiteter beroende på lösning)

## Junction-tabeller
- `BockerForfattare` (Böcker ↔ Författare)
- `Orderrader` (Ordrar ↔ Böcker)

## Viktiga objekt
### Vy: v_TitlarPerFörfattare
Returnerar en rad per författare med:
- Namn
- Ålder
- Antal titlar
- Lagervärde (summa pris * antal i lager)

### Stored Procedure: usp_FlyttaBok
Flyttar ett antal exemplar av en bok från en butik till en annan:
- Kontrollerar att butik och bok finns
- Kontrollerar att saldo räcker
- Kör allt i **transaktion**
- Uppdaterar källlager och mål-lager (skapar rad om den saknas)

### Extra vy: v_OrdrarPerKund
Aggregering som visar antal ordrar per kund (kan användas för kundanalys).

## Hur man kör (SQL Server / SSMS)
1. Öppna **SQL Server Management Studio (SSMS)**
2. Välj rätt databas (ex: `Bokhandel`) eller skapa den först:
   ```sql
   CREATE DATABASE Bokhandel;
   GO
   USE Bokhandel;
   GO
