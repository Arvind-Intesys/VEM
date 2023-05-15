/****** Object:  StoredProcedure [dbo].[sp_GetProgettoDetails]    Script Date: 09/10/2019 10:55:40 ******/


/**********************
Come si usa: se voglio ottenere informazioni sul progetto con codice 'MioPrg'

exec dbo.sp_getProgettoDetails 'MioPrg'

e poi
select * from ##MioPrg

oppure

select RagioneSociale from ##MioPrg

e così via

********************/


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_GetProgettoDetails](@CodiceProgetto nvarchar(max))
AS
BEGIN
DECLARE @intro nvarchar(max)
DECLARE @coda nvarchar(max)
DECLARE @DatoPers nvarchar(max)
DECLARE @IDCdataField int
DECLARE @Cdataname nvarchar(max)
DECLARE @CdataType int
DECLARE @CdataTypeString nvarchar(max)
DECLARE @CdataSectionName nvarchar(max)
DECLARE @CastFormat nvarchar(max)
DECLARE @IDProgetto int
DECLARE @IDTipoProgetto int

set @IDProgetto = (SELECT TOP 1 ID_PROGETTO FROM PRG_PROGETTI WHERE COD_PROGETTO = @CodiceProgetto)
IF @IDProgetto IS NOT NULL
BEGIN
	set @IDTipoProgetto = (select ID_TIPO_PROGETTO from PRG_PROGETTI where ID_PROGETTO = @IDProgetto)

	DECLARE DatiPers CURSOR FOR
		SELECT ID_CDATA_FLD, CDATA_NAME, CDATA_TYPE, sec.CDATA_SECTION_DESCRIPTION FROM CDATA_FIELDS fie
		INNER JOIN CDATA_SECTIONS sec ON fie.ID_CDATA_SEC = sec.ID_CDATA_SEC AND sec.ATTIVO = 'Y' AND sec.KORD_APP = 38
		INNER JOIN CDATA_MODULE_TYPE mt ON mt.ID_CDATA_SEC = sec.ID_CDATA_SEC AND mt.ID_TIPO = @IDTipoProgetto
		where fie.ATTIVO = 'Y' 
		order by sec.SEQUENZA, fie.SEQUENZA

	set @DatoPers = ''
	OPEN DatiPers
	FETCH NEXT FROM DatiPers INTO  @IDCdataField, @Cdataname, @CdataType, @CdataSectionName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @CdataTypeString = CASE @CdataType
				WHEN 1 THEN 'Int'
				WHEN 2 THEN 'Float'
				WHEN 3 THEN 'Boolean'
				WHEN 4 THEN 'Combo'
				WHEN 5 THEN 'Text'
				WHEN 6 THEN 'Memo'
				WHEN 7 THEN 'Date'
				END
		SET @CastFormat = CASE @CdataType
				WHEN 1 THEN 'Integer'
				WHEN 2 THEN 'Float'
				WHEN 3 THEN 'Boolean'
				WHEN 4 THEN 'Combo'
				WHEN 5 THEN 'Text'
				WHEN 6 THEN 'Memo'
				WHEN 7 THEN 'Date'
				END

		IF @CdataType IN (4,5,6) --String CustomData
		BEGIN
			SET @DatoPers = @DatoPers + ', dbo.sf_get' + @CdataTypeString + 'CustomData(38, ' + CAST(@IDProgetto as nvarchar(10))+ ',' + CAST(@IDCdataField as nvarchar(10))+') as [' + @CdataSectionName + ' - ' +@Cdataname + ']'
		END
		ELSE IF @CdataType IN (1,2,3,7)
		BEGIN
			SET @DatoPers = @DatoPers + ', CAST( dbo.sf_get' + @CdataTypeString + 'CustomData(38, ' + CAST(@IDProgetto as nvarchar(10))+ ',' + CAST(@IDCdataField as nvarchar(10))+') AS '+@CastFormat + ' ) as [' + @CdataSectionName + ' - '+ @Cdataname + ']'
			END
		ELSE  -- Module Custom Data
		BEGIN
			SET @DatoPers = @DatoPers + ', dbo.sf_getModuleCustomData(38, ' + CAST(@IDProgetto as nvarchar(10))+ ',' + CAST(@IDCdataField as nvarchar(10))+',' + CAST(@CdataType as nvarchar(10)) + ') as ['+ @CdataSectionName + ' - ' + @Cdataname + ']'
		END


		FETCH NEXT FROM DatiPers INTO  @IDCdataField, @Cdataname, @CdataType, @CdataSectionName
		END

	CLOSE DatiPers
	DEALLOCATE DatiPers


	select @intro = ' IF EXISTS(SELECT [name] FROM tempdb.sys.tables WHERE [name] = ''##'+ @CodiceProgetto + ''')
   DROP TABLE ##' +  @CodiceProgetto +'; select * into ##' + @CodiceProgetto +' from (select ID_PROGETTO as IDProgetto, tip.DESCR_TIPO_PROGETTO as TipoProgetto, COD_PROGETTO as [CodiceProgetto], DESCR_PROGETTO as DescrizioneProgetto,
	 gcf.COD_CONTO as CodiceCliente, gcf.RAGIONE_SOCIALE as RagioneSociale, ID_ARTICOLO'
	select @coda = ' from PRG_PROGETTI prg 
	INNER JOIN PRG_TIPI_PROGETTO tip ON tip.ID_TIPO_PROGETTO = prg.ID_TIPO_PROGETTO
	LEFT OUTER JOIN GCF_ANAGRAFICA gcf ON gcf.ID_CONTO = prg.ID_CONTO
	 where ID_PROGETTO = ' + CAST(@IDProgetto as nvarchar(10)) + ' ) temp; '

	exec (@intro +@DatoPers + @coda)
	END
END


GO
