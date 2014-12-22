USE [Productions_MSCRM]
GO

/****** Object:  View [dbo].[vw_ServicesRevenueForecastReport_run_1]    Script Date: 10/24/2013 16:35:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





ALTER VIEW [dbo].[vw_ServicesRevenueForecastReport_run_1] 
AS
SELECT Ext.new_title AS [Title]
	, Ext.new_StartDate AS [Project Start Date]
	, Ext.new_EstCompletion AS [Project Estimated Completion]
	, Ext.cust_ProjectedBookedServicesRevenue AS [Projected Booked Services Revenue]
	, Ext.cust_ServicesRevenue AS [Services Revenue]
	, CASE M.new_CompletedYN WHEN 1 THEN 'True' WHEN 0 THEN 'False' ELSE '' END AS [Completed]
	, ISNULL(Ext.new_salesorder_temp, '') AS [Sales Order]	
	, Ext.new_customerPO AS [Customer PO], Ext.cust_CustomerPOreceivedDate AS [Customer PO Received Date]
	, CASE Ext.new_COSreceived WHEN 1 THEN 'True' WHEN 0 THEN 'False' ELSE '' END AS [COS Received]
	, Ext.cust_COSreceivedDate AS [COS Received Date]

	, M.cust_Milestones AS [Milestone Name]
	/* , M.cust_Milestone AS [Milestone Stage] */
	, ISNULL( CONVERT( VARCHAR(10), M.cust_PctRevenueToBeBilled ) + '%', '' ) AS [% Of Revenue To Be Billed]
	, M.cust_Revenue AS [Milestone Revenue] 
	, M.new_milestonetargetstartdate AS [Milestone Target Start Date], M.new_milestoneactualstartdate AS [Milestone Actual Start Date]
	, M.cust_MilestoneTargetDate AS [Milestone Target Completion Date], M.cust_MilestoneCompletionDate AS [Milestone Actual Completion Date]
	/* , ISNULL(Op3.[Value], '') AS [Milestone Per Project] */

	FROM cust_projectmilestonesExtensionBase AS M, 
		new_projectExtensionBase AS Ext,
		new_projectBase AS P
	/* LEFT JOIN StringMapBase AS Op3 ON Op3.AttributeName LIKE 'cust_milestoneperproject' 
		AND Op3.AttributeValue = Ext.cust_MilestonePerProject */
	WHERE P.new_ProjectID = Ext.new_ProjectID AND Ext.new_ProjectID = M.new_Project
		/* AND P.statecode = 0 */ /* 0 is active; 1 is inactive */
		AND M.cust_Revenue IS NOT NULL AND M.cust_Revenue <> 0
		AND ( M.cust_MilestoneTargetDate BETWEEN DATEADD(m,DATEDIFF(m,0,getdate()),0) 
			AND DATEADD( s, -1, DATEADD( mm, DATEDIFF( m, 0, GETDATE()) + 6, 0 ))) 

UNION

SELECT Opp.Name AS [Title], Opp.EstimatedCloseDate AS [Project Start Date]
	, NULL AS [Project Estimated Completion]
	, Ext.cust_ServicesRevenue AS [Projected Booked Services Revenue]
	, NULL AS [Services Revenue], 'False' AS [Completed], '' AS [Sales Order]
	, Ext.new_POnumber AS [Customer PO], NULL AS [Customer PO Received Date]
	, '' AS [COS Received], NULL AS [COS Received Date]
	, '' as [Milestone Name], '' AS [% Of Revenue To Be Billed]
	, Ext.cust_ServicesRevenue AS [Milestone Revenue]
	, NULL AS [Milestone Target Start Date], NULL AS [Milestone Actual Start Date]
	, Opp.EstimatedCloseDate AS [Milestone Target Completion Date]
	, NULL AS [Milestone Actual Completion Date] 
	FROM OpportunityBase AS Opp, OpportunityExtensionBase AS Ext
	WHERE Opp.OpportunityID = Ext.OpportunityID
		AND Opp.StateCode = 0 /* StateCode = 0 Open; 1 Won; 2 Lost */
		AND ( Ext.new_closeprobability = 20 OR Ext.new_closeprobability = 30 )
		AND Ext.cust_ServicesRevenue IS NOT NULL AND Ext.cust_ServicesRevenue <> 0
		AND Ext.new_Region = 279640000 /* USA */
		AND ( Opp.EstimatedCloseDate BETWEEN DATEADD(m,DATEDIFF(m,0,getdate()),0) 
			AND DATEADD( s, -1, DATEADD( mm, DATEDIFF( m, 0, GETDATE()) + 6, 0 ))) 
	;		

	




GO


