USE [Productions_MSCRM]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[vw_ServicesRevenueForecastReport_run_1] 
AS 
	/* ORDER BY is not allowed in a SQL View.
	
	Reference source: http://www.mysamplecode.com/2012/01/sql-view-order-by-clause.html
		An approach to add ORDER BY to a SQL View
	 */
	SELECT TOP 100 PERCENT * FROM	
	(
		SELECT TOP 100 PERCENT * FROM 
		(
			SELECT TOP 100 PERCENT ProjE.new_title AS [Title]
				, CONVERT( DATETIME, ProjE.new_StartDate ) AS [Project Start Date]
				, CONVERT( DATETIME, ProjE.new_EstCompletion ) AS [Project Estimated Completion]
				, ISNULL( Acc1.Name, '' ) AS [Invoice Acct]
				, ISNULL( Acc2.Name, '' ) AS [Project End User]
				, ISNULL( Reg.Value, '' ) AS [Region]	
				, ProjE.cust_ProjectedBookedServicesRevenue AS [Projected Booked Services Revenue]
				, ProjE.cust_ServicesRevenue AS [Services Revenue]
				, CASE Me.new_CompletedYN WHEN 1 THEN 'True' WHEN 0 THEN 'False' ELSE '' END AS [Completed]
				, CONVERT( DECIMAL, ProjE.new_salesorder_temp ) AS [Sales Order]	
				, ISNULL( CONVERT( VARCHAR(50), ProjE.new_customerPO ), '' ) AS [Customer PO]
				, CONVERT( DATETIME, ProjE.cust_CustomerPOreceivedDate ) AS [Customer PO Received Date]
				, CASE ProjE.new_COSreceived WHEN 1 THEN 'True' WHEN 0 THEN 'False' ELSE '' END AS [COS Received]
				, CONVERT( DATETIME, ProjE.cust_COSreceivedDate ) AS [COS Received Date]

				, Me.cust_Milestones AS [Milestone Name]
				/* , Me.cust_Milestone AS [Milestone Stage] */
				, ISNULL( CONVERT( VARCHAR(10), Me.cust_PctRevenueToBeBilled ) + '%', '' ) AS [% Of Revenue To Be Billed]
				, Me.cust_Revenue AS [Milestone Revenue] 
				, CONVERT( DATETIME, Me.new_milestonetargetstartdate ) AS [Milestone Target Start Date]
				, CONVERT( DATETIME, Me.new_milestoneactualstartdate ) AS [Milestone Actual Start Date]
				/* the following label [Milestone Target Completion Date] should be [Milestone Planned Revenue Date] in reality */ 
				, CASE Me.new_CompletedYN WHEN 0 THEN ISNULL( CONVERT( VARCHAR, Me.cust_PlannedRevenueDate, 101 ), '' ) ELSE 
					CONVERT( DATETIME, Me.cust_ActualRevenueDate ) END AS [Milestone Target Completion Date]
				, CONVERT( DATETIME, Me.cust_MilestoneCompletionDate ) AS [Milestone Actual Completion Date]
				/* , ISNULL(Op3.[Value], '') AS [Milestone Per Project] */

				FROM cust_projectmilestonesExtensionBase AS Me
					, new_projectBase AS Proj
					, new_projectExtensionBase AS ProjE
					LEFT OUTER JOIN AccountBase AS Acc1 ON Acc1.AccountID = ProjE.new_InvoiceAccount
					LEFT OUTER JOIN AccountBase AS Acc2 ON Acc2.AccountID = ProjE.new_ProjectEndUser
				/* LEFT JOIN StringMapBase AS Op3 ON Op3.AttributeName LIKE 'cust_milestoneperproject' 
					AND Op3.AttributeValue = ProjE.cust_MilestonePerProject */
					LEFT JOIN StringMapBase AS Reg ON Reg.AttributeName LIKE 'cust_region'
						AND Reg.AttributeValue = ProjE.cust_region	
				WHERE Proj.new_ProjectID = ProjE.new_ProjectID AND ProjE.new_ProjectID = Me.new_Project
					/* AND Proj.statecode = 0 */ /* 0 is active; 1 is inactive */
					AND Me.cust_Revenue IS NOT NULL AND Me.cust_Revenue <> 0
					AND (
							( Me.new_CompletedYN = 0 
								AND Me.cust_PlannedRevenueDate BETWEEN DATEADD(m,DATEDIFF(m,0,getdate()),0) 
								AND DATEADD( s, -1, DATEADD( mm, DATEDIFF( m, 0, GETDATE()) + 6, 0 ))) 
							OR
							( Me.new_CompletedYN = 1 
								AND Me.cust_ActualRevenueDate BETWEEN DATEADD(m,DATEDIFF(m,0,getdate()),0) 
								AND DATEADD( s, -1, DATEADD( mm, DATEDIFF( m, 0, GETDATE()) + 6, 0 ))) 
						)
				ORDER BY [Milestone Target Completion Date] ASC		

			UNION

			SELECT TOP 100 PERCENT Opp.Name AS [Title]
				, CONVERT( DATETIME, Opp.EstimatedCloseDate ) AS [Project Start Date]
				, NULL AS [Project Estimated Completion]
				, '' AS [Invoice Acct], '' AS [Project End User]
				, ISNULL( Reg.Value, '' ) AS [Region]	
				, OppE.cust_ServicesRevenue AS [Projected Booked Services Revenue]
				, NULL AS [Services Revenue], 'False' AS [Completed], NULL AS [Sales Order]
				, ISNULL( CONVERT( VARCHAR(50), OppE.new_POnumber ), '' ) AS [Customer PO], '' AS [Customer PO Received Date]
				, '' AS [COS Received], NULL AS [COS Received Date]
				, '' as [Milestone Name], '' AS [% Of Revenue To Be Billed]
				, OppE.cust_ServicesRevenue AS [Milestone Revenue]
				, NULL AS [Milestone Target Start Date], NULL AS [Milestone Actual Start Date]
				/* the following label [Milestone Target Completion Date] should be [Milestone Planned Revenue Date] in reality */ 
				, CONVERT( DATETIME, Opp.EstimatedCloseDate ) AS [Milestone Target Completion Date]
				, NULL AS [Milestone Actual Completion Date] 
				FROM OpportunityBase AS Opp
					, OpportunityExtensionBase AS OppE
					LEFT JOIN StringMapBase AS Reg ON Reg.AttributeName LIKE 'new_region'
						AND Reg.AttributeValue = OppE.new_region	
				WHERE Opp.OpportunityID = OppE.OpportunityID
					AND Opp.StateCode = 0 /* StateCode = 0 Open; 1 Won; 2 Lost */
					AND OppE.new_closeprobability >= 20 AND OppE.new_closeprobability <= 40 
					AND OppE.cust_ServicesRevenue IS NOT NULL AND OppE.cust_ServicesRevenue <> 0
					/* Americas	= 279640000 
						Asia Pacific = 279640001
						EMEA = 279640002 */
					AND ( OppE.new_Region = 279640000 OR OppE.new_Region = 279640002 )
					AND ( Opp.EstimatedCloseDate BETWEEN DATEADD(m,DATEDIFF(m,0,GETDATE()),0) 
						AND DATEADD( s, -1, DATEADD( mm, DATEDIFF( m, 0, GETDATE()) + 6, 0 ))) 
				ORDER BY [Milestone Target Completion Date]			
		) AS T1
	) AS T2		
	ORDER BY [Milestone Target Completion Date];			

GO


