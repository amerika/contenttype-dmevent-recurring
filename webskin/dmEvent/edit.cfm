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
	
	<cfset getMetaData = application.stCOAPI.dmEvent.qMetadata />
	
	<!--- Wizard steps --->
	<cfquery dbtype="query" name="qWizardSteps">
		SELECT ftWizardStep
		FROM getMetaData
		WHERE ftWizardStep <> 'dmEvent' AND ftWizardStep != ''
		Group By ftWizardStep
		ORDER BY ftSeq
	</cfquery>
	
	<!--- Logic --->
	<cfset realID = stObj.objectID />
	<cfif trim(stObj.versionID) NEQ "">
		<cfset realID = stObj.versionID />
	</cfif>
	<!--- Check if this has childs / is master --->
	<cfset bDactivateReccuring = application.fapi.getContentObjects(typename="dmEvent", masterID_eq=realID).recordCount GT 0 />
	
	<!--- Check if this has master --->
	<cfif bDactivateReccuring IS false>
		<cfset bDactivateReccuring = trim(stObj.masterID) GT 0 />
	</cfif>
	
	<cfloop query="qWizardSteps">
		<cfif qWizardSteps.ftWizardStep IS "Repetisjon" AND bDactivateReccuring IS true>
			<wiz:step name="#qWizardSteps.ftWizardStep#">
				<cfoutput>
					<div style="background-color:##E8E8E8;padding:15px;border-radius:10px">
						<p>Repetisjonsvalene er deaktiverte pga. at denne eventen allerede repeterer.</p>
					</div>
					
				</cfoutput>
				<wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="recurringSetting,recurringEndDate" legend="Repetisjonvalg" stPropMetadata="#{recurringSetting.ftDisplayOnly=true,recurringEndDate.ftDisplayOnly=true}#" />
			</wiz:step>
		<cfelse>
			<wiz:step name="#qWizardSteps.ftWizardStep#" autoGetFields="true">
		</cfif>

	</cfloop>

	<!--- <wiz:step name="General Details" autoGetFields="true"></wiz:step>
	
	<wiz:step name="Event Details" autoGetFields="true"></wiz:step>
	
	<wiz:step name="Avansert" autoGetFields="true">
		<!--- TODO: Deaktiver hvis denne allerede har childs --->
		<!--- <wiz:object objectID="#stWizard.PrimaryObjectID#" lfields="teaser,icon" legend="Annet" HelpSection="Hvis siden du redigerer skal ha en teaser på fremsiden må disse valgene være fylt ut." /> --->
	</wiz:step> --->
	
</wiz:wizard>

<cfsetting enablecfoutputonly="false" />