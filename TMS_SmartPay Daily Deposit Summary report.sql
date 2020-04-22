IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE [name] = 'prc_MY_SMARTpayTMSDeposits_Email' AND [type] IN ('P', 'PC', 'RF', 'X') )
	DROP PROCEDURE [dbo].[prc_MY_SMARTpayDeposits_Email]
GO

CREATE PROCEDURE [dbo].[prc_MY_SMARTpayTMSDeposits_Email]
AS

/*Daily SMARTpay Deposit Summary*/
DECLARE @Date DATE = '2020-02-07'  --DATEADD(DAY, -1, CAST(GETDATE() AS DATE) )
, @EmailTo VARCHAR(255) = 'funi.ndou@za.g4s.com' --'jack.khoo@ame.g4s.com; najmuddin.naim@ame.g4s.com; teikeng.khaw@safeguards.g4s.com; ts.wong@safeguards.g4s.com; kc.tan@ame.g4s.com; daniel.muthu@ame.g4s.com; skywalker@ame.g4s.com; c360.tms@safeguards.g4s.com;'
, @EmailCC VARCHAR(255) = 'minette.smit@za.g4s.com' --'peter.vdwesthuizen@za.g4s.com; sidalan.moodley@za.g4s.com; systems@za.g4s.com; tms@za.g4s.com;'
, @Subjct VARCHAR(60)
, @Bdy VARCHAR(255)
, @Qry VARCHAR(MAX)
, @FileName VARCHAR(50)

SET @Subjct = 'CashOps:TMS/SmartPay Daily Deposit Summary - ' + CAST(@Date AS VARCHAR)
SET @FileName = 'daily_smartpay_tms_deposit_summary_' + REPLACE( CAST(@Date AS VARCHAR), '-', '') + '.csv'
SET @Bdy = 'Good day,

Here is the daily SMARTpay/TMS deposit summary report for yesterday.

Kind regards,
G4S Safeguards'
----SELECT @Subjct AS Subjct, @FileName AS [FileName], @Bdy AS Body, @EmailTo AS EmailTo

SET @Qry = 'SELECT MachineID
, [Name]
, ClientID
, CAST(Total AS MONEY) AS Total
FROM (

			SELECT 1 AS src
				, CAST(t.FlashNumber AS VARCHAR) AS MachineID
					, LTRIM( RTRIM(c.ClientName) ) AS [Name]
						, LTRIM( RTRIM(c.ClientCode) ) AS ClientID
							, SUM(t.Amount) AS Total
						FROM [SmartPay_uat].dbo.[SP_Device] AS c WITH (NOLOCK)
					INNER JOIN dbo.[SP_DeviceTransaction] AS t WITH (NOLOCK) ON c.FlashNumber = t.FlashNumber
				WHERE t.[Type] = 1
			--AND CAST(t.TransactionDate AS DATE) = ''' + CAST(@Date AS VARCHAR) + '''
		 GROUP BY t.FlashNumber
		, LTRIM( RTRIM(c.ClientName) )
			, LTRIM( RTRIM(c.ClientCode) )	

	Union 

     Select 1 AS src
        ,Machine_ID as MachineID
			 ,LTRIM( RTRIM([S].ClientName) ) AS [Name]
				,LTRIM( RTRIM([S].ClientID) ) AS ClientID
			,SUM([S].Total) AS Total        
		From [Deposita_uat].dbo.MTMSMovementSummary As [S] With (NoLock)
      --Where ([S].DateAdded AS DATE) = ''' + CAST(@Date AS VARCHAR) + '''
    GROUP BY [S].Machine_ID
		,LTRIM( RTRIM([S].ClientName) )
			,LTRIM( RTRIM([S].ClientID) )
	
	) AS src
ORDER BY src
, MachineID'


EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'Systems2' /*UAT*/ --'standard' /*Prod*/
, @recipients = @EmailTo
, @copy_recipients = @EmailCC
, @subject = @Subjct
, @body = @Bdy
, @body_format = 'TEXT'
, @query = @Qry
, @execute_query_database ='SmartPay_uat'--'SmartPay'
, @execute_query_database ='Deposita_uat'--'Deposita'
, @attach_query_result_as_file = 1
, @query_attachment_filename = @FileName
, @query_result_header = 1
, @query_result_width = 1000
, @query_result_no_padding = 1
, @query_result_separator = ','
, @exclude_query_output = 1
, @append_query_error = 0
, @query_no_truncate = 0

GO