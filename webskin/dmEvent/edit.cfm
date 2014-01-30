<cfsetting enablecfoutputonly="true" /> 
<!--- @@Copyright: Copyright (c) 2013 IDLmedia AS. All rights reserved. --->
<!--- @@License:
	
--->
<!--- @@displayname: --->
<!--- @@description: edit --->
<!--- @@author: Jørgen M. Skogås on 2013-04-23 --->

<cfimport taglib="/farcry/core/tags/wizard" prefix="wiz" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<!--- LOCK THE OBJECT --->
<cfset setLock(stObj=stObj,locked=true) />

<!--- Always save wizard WDDX data --->
<wiz:processwizard excludeAction="Cancel">
	<!--- Save the Primary wizard Object --->
	<wiz:processwizardObjects typename="#stobj.typename#" />
</wiz:processwizard>

<!--- Save wizard Data to Database and remove wizard --->
<wiz:processwizard action="Save" Savewizard="true" Exit="true" />

<!--- remove wizard --->
<wiz:processwizard action="Cancel" Removewizard="true" Exit="true" />

<!--- EDIT OBJECT --->
<wiz:wizard ReferenceID="#stObj.objectID#" r_stWizard="stWizard">
	
	<!--- Logic --->
	<cfset realID = stObj.objectID />
	<cfif trim(stObj.versionID) NEQ "">
		<cfset realID = stObj.versionID />
	</cfif>
	<cfquery name="qExists" datasource="#application.dsn#">
		SELECT *
		FROM dmEvent
		WHERE objectID = '#realID#'
	</cfquery>
	<cfdump var="#qExists#" />
	<cfdump var="#stObj#" />
	<cfdump var="#stWizard#" />
	<wiz:step name="General Details" autoGetFields="true">
		<!--- <wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="title,subTitle" legend="Sideegenskaper" />
		<wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="bodyWebskin" legend="Mal" /> --->
	</wiz:step>

	<wiz:step name="Avansert" autoGetFields="true">
		<!--- <wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="teaser,icon" legend="Annet" HelpSection="Hvis siden du redigerer skal ha en teaser på fremsiden må disse valgene være fylt ut." /> --->
	</wiz:step>
	
	<wiz:step name="Event Details" autoGetFields="true">
		<!--- <wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="productID" legend="Fremhevet proukt" />
		<wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="aProductIDs" legend="Fremhevede produkter" /> --->
	</wiz:step>
</wiz:wizard>

<cfsetting enablecfoutputonly="false" />