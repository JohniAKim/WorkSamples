/* ---------------------------------------------------------------------
			Extension List
				
			Example of how to pull a list of properties that
                        have passed the SCOE, along with any extensions
                        that have been requested.

                        NOTE:  We only care about extensions that are 
                        pending that would change the SCOE to a future
                        date.  Extensions requests that have already
                        passed the requested extend to date are no longer
                        valid because the a new extension still needs to 
                        be requested.
				
Created:		2010.10.29 by Johni Kim - Original template.
Modified:	
                        2011.01.14 by Johni Kim - Added criteria to the
                        WHERE clause that filters out deleted properties.
                        These were not seen before because properties
                        are very rarely deleted once they push to the 
                        closing system.

--------------------------------------------------------------------- */

SELECT	
			cp.propertyId
			,[Closer] = cp.closer_coordinator
			,[Closer Name]=cc.coordinator_name
			,[Closing Company]= cp.closingCompanyName
			,[Property ID] = cp.propertyId
			,[Seller] = cp.seller
			,[Loan No.]= p.loanNo
			,[Address]=p.propertyAddress
			,[Scheduled Close Date]=cp.estClosingDate
			,[Decision] = 
			CASE
				-- Pending Cancellations - Extensions do not matter
				WHEN cp.closing_status = 'Pending Cancellation' THEN 'Pending Cancellation'
				-- If no ext_id, then there is no current extension
				WHEN curExt.ext_id IS NULL THEN 'Pending'
				-- Show the status of the Current Extension.  Statuses we don't care about
				-- are taken care of in the SELECT statement that builds curExt				
				ELSE 
					/* 
						NOTE:  The following line is what we really need to use but is not
						available until it is added to the table.
					*/
					curExt.extStatus
					--curExt.is_approved
			END
			,[Original SCOE]=p.estClosingDateOriginal
			,[Requested Close Date]=curExt.extendToDate
			,[Extensions] =NULL
			,[Previous Extension Request Reasons]=NULL
			,[Seller or Buyer Delay] = curExt.delayCode
			,[Primary Reason for Request] = curExt.delayDescription
			,[Detailed Reason] = curExt.extComments
			,[Status]=curExt.extStatus
			,[Property Status]=p.status
			,p.closing_status
			,p.soldStatus
			,p.auctID
FROM
			Stage.dbo.REO_Property p
			LEFT JOIN Stage.dbo.REO_closing_property cp ON cp.propertyId = p.propertyId
                        -- The following sub query encapsulates the logic for determining a valid Current Extension
                        -- request.  
			LEFT JOIN (
					SELECT
								cd.delayCode
								,cd.delayDescription
								,cde.*
					FROM
								Stage.dbo.REO_closing_delay cd
								INNER JOIN Stage.dbo.REO_closing_delay_extensions cde ON cd.delay_Id = cde.delay_Id
					WHERE		
								cde.is_approved = 'Pending'
								AND cde.extendToDate > GETDATE()					
			) curExt ON cp.propertyId = curExt.propertyId
			LEFT JOIN Stage.dbo.REO_closing_coordinator cc ON cc.cc_id = p.closer_coordinator

WHERE		
			cp.closing_status IN ('Active','Pending Cancellation')
			AND ((cp.estClosingDate <= GETDATE())
				OR (curExt.extendToDate >= GETDATE()))
			AND (p.auctID NOT LIKE 'T%')
			AND (p.status NOT LIKE 'Deleted')