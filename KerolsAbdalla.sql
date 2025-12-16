/* Laboration 2 – Bokhandel
   SQL Server (T-SQL) – tabeller, relationer, testdata, vyer, SP och tester
*/

USE Bokhandel;
GO

/* --- Rensa objekt --- */
DROP VIEW IF EXISTS dbo.v_TitlarPerFörfattare;
DROP VIEW IF EXISTS dbo.v_OrdrarPerKund;
DROP PROCEDURE IF EXISTS dbo.usp_FlyttaBok;
GO

DROP TABLE IF EXISTS dbo.Orderrader;
DROP TABLE IF EXISTS dbo.BokFörfattare;
DROP TABLE IF EXISTS dbo.LagerSaldo;
DROP TABLE IF EXISTS dbo.Ordrar;
DROP TABLE IF EXISTS dbo.Kunder;
DROP TABLE IF EXISTS dbo.Butiker;
DROP TABLE IF EXISTS dbo.Böcker;
DROP TABLE IF EXISTS dbo.Betalningssätt;
DROP TABLE IF EXISTS dbo.Kategorier;
DROP TABLE IF EXISTS dbo.Förlag;
DROP TABLE IF EXISTS dbo.Författare;
GO

/* --- Grundtabeller --- */
CREATE TABLE dbo.Författare (
    ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Förnamn NVARCHAR(50) NOT NULL,
    Efternamn NVARCHAR(50) NOT NULL,
    Födelsedatum DATE NOT NULL
);
GO

CREATE TABLE dbo.Förlag (
    FörlagID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Namn NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.Kategorier (
    KategoriID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Namn NVARCHAR(50) NOT NULL UNIQUE
);
GO

/* Extra entitet: kopplas till ordrar */
CREATE TABLE dbo.Betalningssätt (
    BetalningssättID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Namn NVARCHAR(50) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.Böcker (
    ISBN13 CHAR(13) NOT NULL PRIMARY KEY,
    Titel NVARCHAR(100) NOT NULL,
    Språk NVARCHAR(20) NOT NULL,
    Pris DECIMAL(8,2) NOT NULL,
    Utgivningsdatum DATE NOT NULL,
    FörfattareID INT NOT NULL,   -- huvudförfattare
    FörlagID INT NOT NULL,
    KategoriID INT NOT NULL,

    CONSTRAINT CK_Böcker_ISBN13_Digits CHECK (ISBN13 NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_Böcker_Pris_Pos CHECK (Pris > 0),

    CONSTRAINT FK_Böcker_Författare FOREIGN KEY (FörfattareID) REFERENCES dbo.Författare(ID),
    CONSTRAINT FK_Böcker_Förlag FOREIGN KEY (FörlagID) REFERENCES dbo.Förlag(FörlagID),
    CONSTRAINT FK_Böcker_Kategori FOREIGN KEY (KategoriID) REFERENCES dbo.Kategorier(KategoriID)
);
GO

/* Flera författare per bok */
CREATE TABLE dbo.BokFörfattare (
    ISBN13 CHAR(13) NOT NULL,
    FörfattareID INT NOT NULL,
    CONSTRAINT PK_BokFörfattare PRIMARY KEY (ISBN13, FörfattareID),
    CONSTRAINT FK_BokFörfattare_Bok FOREIGN KEY (ISBN13) REFERENCES dbo.Böcker(ISBN13) ON DELETE CASCADE,
    CONSTRAINT FK_BokFörfattare_Författare FOREIGN KEY (FörfattareID) REFERENCES dbo.Författare(ID)
);
GO

CREATE TABLE dbo.Butiker (
    ButikID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Butiksnamn NVARCHAR(100) NOT NULL,
    Adress NVARCHAR(100) NOT NULL,
    Postnummer NVARCHAR(10) NOT NULL,
    Stad NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.LagerSaldo (
    ButikID INT NOT NULL,
    ISBN13 CHAR(13) NOT NULL,
    Antal INT NOT NULL,

    CONSTRAINT PK_LagerSaldo PRIMARY KEY (ButikID, ISBN13),
    CONSTRAINT CK_LagerSaldo_Antal CHECK (Antal >= 0),

    CONSTRAINT FK_LagerSaldo_Butik FOREIGN KEY (ButikID) REFERENCES dbo.Butiker(ButikID),
    CONSTRAINT FK_LagerSaldo_Bok FOREIGN KEY (ISBN13) REFERENCES dbo.Böcker(ISBN13)
);
GO

/* Extra tabeller för handel */
CREATE TABLE dbo.Kunder (
    KundID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Förnamn NVARCHAR(50) NOT NULL,
    Efternamn NVARCHAR(50) NOT NULL,
    Epost NVARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE dbo.Ordrar (
    OrderID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    OrderDatum DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    KundID INT NOT NULL,
    ButikID INT NOT NULL,
    BetalningssättID INT NOT NULL,

    CONSTRAINT FK_Ordrar_Kund FOREIGN KEY (KundID) REFERENCES dbo.Kunder(KundID),
    CONSTRAINT FK_Ordrar_Butik FOREIGN KEY (ButikID) REFERENCES dbo.Butiker(ButikID),
    CONSTRAINT FK_Ordrar_Betal FOREIGN KEY (BetalningssättID) REFERENCES dbo.Betalningssätt(BetalningssättID)
);
GO

CREATE TABLE dbo.Orderrader (
    OrderID INT NOT NULL,
    ISBN13 CHAR(13) NOT NULL,
    Antal INT NOT NULL,
    PrisVidKöp DECIMAL(8,2) NOT NULL,

    CONSTRAINT PK_Orderrader PRIMARY KEY (OrderID, ISBN13),
    CONSTRAINT CK_Orderrader_Antal CHECK (Antal > 0),
    CONSTRAINT CK_Orderrader_Pris CHECK (PrisVidKöp > 0),

    CONSTRAINT FK_Orderrader_Order FOREIGN KEY (OrderID) REFERENCES dbo.Ordrar(OrderID) ON DELETE CASCADE,
    CONSTRAINT FK_Orderrader_Bok FOREIGN KEY (ISBN13) REFERENCES dbo.Böcker(ISBN13)
);
GO

/* --- Testdata --- */
INSERT INTO dbo.Författare (Förnamn, Efternamn, Födelsedatum) VALUES
(N'Emma', N'Askling', '1981-05-12'),
(N'Johan', N'Lindqvist', '1975-07-23'),
(N'Lisa', N'Lund', '1990-11-02'),
(N'Karl', N'Karlsson', '1960-02-17');
GO

INSERT INTO dbo.Förlag (Namn) VALUES
(N'Norrsken Förlag'),
(N'Sydstjärnan Förlag'),
(N'Österlind Förlag'),
(N'Västmark Förlag');
GO

INSERT INTO dbo.Kategorier (Namn) VALUES
(N'Deckare'),
(N'Roman'),
(N'Barnbok'),
(N'Fantasy'),
(N'Facklitteratur');
GO

INSERT INTO dbo.Betalningssätt (Namn) VALUES
(N'Kort'),
(N'Swish'),
(N'Faktura');
GO

INSERT INTO dbo.Böcker (ISBN13, Titel, Språk, Pris, Utgivningsdatum, FörfattareID, FörlagID, KategoriID) VALUES
('9780000000001', N'Mörkret under ytan',    N'Svenska', 219.00, '2020-03-15', 1, 1, 1),
('9780000000002', N'En andra chans',        N'Svenska', 159.00, '2018-07-01', 1, 2, 2),
('9780000000003', N'Dödligt avslöjande',    N'Svenska', 239.00, '2021-05-20', 1, 1, 1),
('9780000000004', N'Skuggor över Sundet',   N'Svenska', 189.00, '2019-11-10', 2, 1, 1),
('9780000000005', N'Äventyr i skogen',      N'Svenska',  99.00, '2015-09-05', 3, 3, 3),
('9780000000006', N'Draksvärdet',           N'Svenska', 249.00, '1995-04-12', 4, 4, 4),
('9780000000007', N'Skogens hjältar',       N'Svenska', 199.00, '1998-08-30', 4, 4, 4),
('9780000000008', N'Magiens väg',           N'Svenska', 199.00, '2005-01-20', 4, 4, 4),
('9780000000009', N'Kungens fall',          N'Svenska', 149.00, '2010-06-14', 4, 4, 4),
('9780000000010', N'Min väg till fantasin', N'Svenska', 279.00, '2020-10-01', 4, 2, 5);
GO

/* Koppla författare till böcker (inkl. ett exempel med två författare) */
INSERT INTO dbo.BokFörfattare (ISBN13, FörfattareID) VALUES
('9780000000001', 1),
('9780000000002', 1),
('9780000000003', 1),
('9780000000003', 2),  -- extra författare på samma bok
('9780000000004', 2),
('9780000000005', 3),
('9780000000006', 4),
('9780000000007', 4),
('9780000000008', 4),
('9780000000009', 4),
('9780000000010', 4);
GO

INSERT INTO dbo.Butiker (Butiksnamn, Adress, Postnummer, Stad) VALUES
(N'Bokhandel Stockholm', N'Drottninggatan 1', '11144', N'Stockholm'),
(N'Bokhandel Göteborg',  N'Kungsportsavenyn 5', '41136', N'Göteborg'),
(N'Bokhandel Malmö',     N'Stortorget 10', '21122', N'Malmö');
GO

INSERT INTO dbo.LagerSaldo (ButikID, ISBN13, Antal) VALUES
(1, '9780000000001', 4),
(2, '9780000000001', 3),
(1, '9780000000002', 5),
(1, '9780000000003', 2),
(3, '9780000000003', 5),
(2, '9780000000004', 4),
(3, '9780000000004', 2),
(3, '9780000000005', 7),
(1, '9780000000006', 3),
(2, '9780000000006', 5),
(3, '9780000000006', 4),
(1, '9780000000007', 6),
(2, '9780000000007', 2),
(3, '9780000000007', 3),
(1, '9780000000008', 4),
(2, '9780000000009', 3),
(3, '9780000000010', 2);
GO

INSERT INTO dbo.Kunder (Förnamn, Efternamn, Epost) VALUES
(N'Anna', N'Andersson', N'anna@test.se'),
(N'Bengt', N'Björk', N'bengt@test.se'),
(N'Cecilia', N'Carlsson', N'cecilia@test.se'),
(N'David', N'Dahl', N'david@test.se'),
(N'Erica', N'Ek', N'erica@test.se');
GO

INSERT INTO dbo.Ordrar (OrderDatum, KundID, ButikID, BetalningssättID) VALUES
('2024-01-10', 1, 1, 1),
('2024-02-05', 1, 1, 2),
('2024-03-12', 1, 1, 1),
('2024-02-20', 2, 2, 1),
('2024-06-30', 2, 2, 3),
('2024-07-15', 3, 3, 2),
('2024-09-01', 4, 1, 1);
GO

/* PrisVidKöp sparas för att kunna summera ordervärde korrekt */
INSERT INTO dbo.Orderrader (OrderID, ISBN13, Antal, PrisVidKöp) VALUES
(1, '9780000000001', 1, 219.00),
(1, '9780000000002', 1, 159.00),
(2, '9780000000003', 1, 239.00),
(3, '9780000000006', 1, 249.00),
(4, '9780000000001', 1, 219.00),
(4, '9780000000004', 2, 189.00),
(5, '9780000000007', 1, 199.00),
(6, '9780000000005', 1,  99.00),
(7, '9780000000008', 1, 199.00);
GO

/* --- Vy: titlar och lagervärde per författare --- */
CREATE VIEW dbo.v_TitlarPerFörfattare
AS
SELECT
    Namn = CONCAT(f.Förnamn, N' ', f.Efternamn),
    Ålder = CONCAT(
        DATEDIFF(YEAR, f.Födelsedatum, CAST(GETDATE() AS DATE))
        - CASE
            WHEN DATEADD(YEAR, DATEDIFF(YEAR, f.Födelsedatum, CAST(GETDATE() AS DATE)), f.Födelsedatum) > CAST(GETDATE() AS DATE)
            THEN 1 ELSE 0
          END,
        N' år'
    ),
    Titlar = CONCAT(COUNT(DISTINCT bf.ISBN13), N' st'),
    Lagervärde = CONCAT(
        CONVERT(INT, ROUND(ISNULL(SUM(b.Pris * ls.Antal), 0), 0)),
        N' kr'
    )
FROM dbo.Författare f
LEFT JOIN dbo.BokFörfattare bf ON bf.FörfattareID = f.ID
LEFT JOIN dbo.Böcker b ON b.ISBN13 = bf.ISBN13
LEFT JOIN dbo.LagerSaldo ls ON ls.ISBN13 = b.ISBN13
GROUP BY f.Förnamn, f.Efternamn, f.Födelsedatum;
GO

/* --- Extra vy: kundöversikt (antal ordrar + totalvärde)
   Nytta: se aktiva kunder och deras köpbeteende.
*/
CREATE VIEW dbo.v_OrdrarPerKund
AS
SELECT
    KundNamn = CONCAT(k.Förnamn, N' ', k.Efternamn),
    AntalOrdrar = COUNT(DISTINCT o.OrderID),
    TotaltOrdervärde = CONVERT(INT, ROUND(ISNULL(SUM(r.Antal * r.PrisVidKöp), 0), 0))
FROM dbo.Kunder k
LEFT JOIN dbo.Ordrar o ON o.KundID = k.KundID
LEFT JOIN dbo.Orderrader r ON r.OrderID = o.OrderID
GROUP BY k.Förnamn, k.Efternamn;
GO

/* --- SP: flytta böcker mellan butiker --- */
CREATE PROCEDURE dbo.usp_FlyttaBok
    @FranButikID INT,
    @TillButikID INT,
    @ISBN13 CHAR(13),
    @Antal INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Antal IS NULL OR @Antal < 1
        THROW 50001, 'Antal måste vara minst 1.', 1;

    IF @FranButikID = @TillButikID
        THROW 50002, 'Från- och tillbutik får inte vara samma.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Butiker WHERE ButikID = @FranButikID)
        THROW 50003, 'Källbutik finns inte.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Butiker WHERE ButikID = @TillButikID)
        THROW 50004, 'Målbutik finns inte.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Böcker WHERE ISBN13 = @ISBN13)
        THROW 50005, 'Boken finns inte.', 1;

    BEGIN TRAN;

    BEGIN TRY
        DECLARE @Nuvarande INT;

        SELECT @Nuvarande = Antal
        FROM dbo.LagerSaldo WITH (UPDLOCK, HOLDLOCK)
        WHERE ButikID = @FranButikID AND ISBN13 = @ISBN13;

        IF @Nuvarande IS NULL
            THROW 50006, 'Boken finns inte i källbutikens lager.', 1;

        IF @Nuvarande < @Antal
            THROW 50007, 'Otillräckligt saldo i källbutiken.', 1;

        UPDATE dbo.LagerSaldo
        SET Antal = Antal - @Antal
        WHERE ButikID = @FranButikID AND ISBN13 = @ISBN13;

        DELETE FROM dbo.LagerSaldo
        WHERE ButikID = @FranButikID AND ISBN13 = @ISBN13 AND Antal = 0;

        IF EXISTS (SELECT 1 FROM dbo.LagerSaldo WHERE ButikID = @TillButikID AND ISBN13 = @ISBN13)
        BEGIN
            UPDATE dbo.LagerSaldo
            SET Antal = Antal + @Antal
            WHERE ButikID = @TillButikID AND ISBN13 = @ISBN13;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.LagerSaldo (ButikID, ISBN13, Antal)
            VALUES (@TillButikID, @ISBN13, @Antal);
        END

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* --- Tester --- */
SELECT * FROM dbo.Författare;
SELECT * FROM dbo.Förlag;
SELECT * FROM dbo.Kategorier;
SELECT * FROM dbo.Betalningssätt;
SELECT * FROM dbo.Böcker;
SELECT * FROM dbo.BokFörfattare;
SELECT * FROM dbo.Butiker;
SELECT * FROM dbo.LagerSaldo;
SELECT * FROM dbo.Kunder;
SELECT * FROM dbo.Ordrar;
SELECT * FROM dbo.Orderrader;

SELECT * FROM dbo.v_TitlarPerFörfattare;
SELECT * FROM dbo.v_OrdrarPerKund;

SELECT * FROM dbo.LagerSaldo WHERE ISBN13 = '9780000000009';
EXEC dbo.usp_FlyttaBok @FranButikID = 2, @TillButikID = 1, @ISBN13 = '9780000000009', @Antal = 2;
SELECT * FROM dbo.LagerSaldo WHERE ISBN13 = '9780000000009';
GO
