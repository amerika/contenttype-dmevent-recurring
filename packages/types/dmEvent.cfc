<!--- @@Copyright: Copyright (c) 2014 Amerika Design & Utvikling AS. All rights reserved. --->
<!--- @@License:
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
--->

<!--- @@displayname: dmEvent.cfc --->
<!--- @@description: There is no description for this template. Please add or remove this message. --->
<!--- @@author: Jørgen M. Skogås (jorgen@amerika.no) on 2014-01-23 --->

<cfcomponent extends="farcry.plugins.farcrycms.packages.types.dmevent">

	<cfproperty ftSeq="100" ftWizardStep="Avansert" ftFieldset="Gjentakende aktivitet"
				name="recurringSetting" type="string" required="true" default=""
				ftLabel="Gjenta" ftType="list" ftList=":Aldri,d:Hver dag,ww:Hver uke,m:Hver måned,yyyy:Hvert år"
				ftHint="Om du endrer på en gjentakende aktivitet, blir alle oppføringer i fortid og fremtid endret slik at innholdet viser det samme som den du endrer på. Aktiviteter som repeterer hvert år og som har startdato 29. februar vil bare repetere hver fjerde år (skuddår)." />
				
	<cfproperty ftseq="101" ftWizardStep="Avansert" ftFieldset="Gjentakende aktivitet"
				name="recurringEndDate" type="date" required="no" default=""
				ftlabel="Stopp gjentaking" ftType="datetime"
				ftDefaultType="Evaluate" ftDefault="DateAdd('d', 365, now())" ftDateFormatMask="dd mmm yyyy" ftTimeFormatMask="hh:mm tt" ftShowTime="false" ftToggleOffDateTime="true"
				ftHint="Siste mulige dag aktiviteten kan repetere på. Systemet har en øvre grense på 100 gjentakninger pr aktivitet, uavhengig om det er satt en sluttdato eller ikke." />
	
	<!--- Hidden --->
	<cfproperty name="masterID" type="UUID" required="false" default="" />
	
	<!--- Methods --->
	<!--- <cffunction name="BeforeSave" access="public" output="true" returntype="struct">
		<cfargument name="stProperties" required="true" type="struct" />
		<cfargument name="stFields" required="true" type="struct" />
		<cfargument name="stFormPost" required="false" type="struct" />
		
		<cfdump var="#arguments#" />
		
		<cfreturn super.BeforeSave(argumentCollection=arguments)>
	</cffunction> --->
	
	<cffunction name="afterSave" access="public" output="true" returntype="struct">
		<cfargument name="stProperties" type="struct" required="true" />

		<cfset var bHasChilds = application.fapi.getContentObjects(typename="dmEvent", masterID_eq=arguments.stProperties.objectID).recordCount GT 0 />
		
		<!--- Only run on events that are set to recurring and when status change from draft to approved --->
		<cfif (arguments.stProperties.recurringSetting IS NOT "") AND
			  (arguments.previousStatus IS "draft" AND arguments.stProperties.status IS 'approved')>
			
	  		<!--- MASTER
	  		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
			<cfif arguments.stProperties.masterID IS "">
				<!--- Create childs --->
				<cfif bHasChilds IS false>
					<cfset stCreateChilds = createChilds(argumentCollection=arguments) />
				<cfelse>
					<cfset stUpdateChilds = updateChilds(argumentCollection=arguments) />
				</cfif>
				
			</cfif>
			
		</cfif>
		
		<!--- CHILD
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- TODO: Sjekk om denne tilhører et master object, hvis det er endringer på dato skal masterID fjernes, det samme med  --->
		
		<cfset stSuper = super.afterSave(stProperties=arguments.stProperties) />
		
		<cfreturn stSuper />
	</cffunction>
	
	<cffunction name="updateMaster" access="public" output="true" returntype="struct">
		<cfargument name="stProperties" type="struct" required="true" />
		<cfset var loopDate = arguments.stProperties.startDate />
		<cfset var counter = 0 />
		<cfset var aRecurringDates = arrayNew(1) />
		<cfset var bHasChilds = application.fapi.getContentObjects(typename="dmEvent", masterID=arguments.stProperties.objectID).recordCount />
		<cfdump var="#arguments#" />
		<!--- MASTER
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- Only run on events that are set to recurring and when status change from draft to approved --->
		<cfif (arguments.stProperties.recurringSetting IS NOT "") AND
			  (arguments.previousStatus IS "draft" AND arguments.stProperties.status IS 'approved')>
			<!--- 
			yyyy: Year (et år)
			m: Month (en måned)
			d: Day (en dag)
			ww: Week (en uke)
			--->
			<!--- TODO: Sjekk om datoen har flyttet på seg, hvis den har det må man kjøre dateAdd på alle child elementer --->
			<!--- TODO: Slett alle fremtidige, må endre på master sin recurringEndDate --->
			
			<!--- TODO: Kalkuler hva recurringEndDate er hvis den ikke er satt --->
			
			<!--- TODO: Loop helt til loopDate er større enn recurringEndDate, eller maks 100 ganger --->
			<cfloop from="1" to="100" index="i">
				<cfset counter = counter + 1 />
				<cfset loopDate = dateAdd(arguments.stProperties.recurringSetting, counter, arguments.stProperties.startDate) />
				<cfif isDate(arguments.stProperties.recurringEndDate) AND dateCompare(loopDate, arguments.stProperties.recurringEndDate, 'd') GTE 1>
					<!--- TODO: Oppdater recurringEndDate hvis den ikke er lik siste loopDate --->
					<cfbreak />
				</cfif>
				<cfset arrayAppend(aRecurringDates, "#loopDate#") />
				<cfoutput>#lsDateFormat(loopDate, "dd. mmmm yyyy")# - #lsDateFormat(loopDate, "dddd")#<br/></cfoutput>
			</cfloop>
			
			<cfdump var="#aRecurringDates#" />
			<cfabort />
		</cfif>
		
		<!--- CHILD
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- TODO: Sjekk om denne tilhører et master object, hvis det er endringer på dato skal masterID fjernes, det samme med  --->
		
		<cfset stSuper = super.afterSave(stProperties=arguments.stProperties) />
		
		<cfreturn stSuper />
	</cffunction>
	
	<cffunction name="createChilds" access="public" output="true" returntype="any">
		<cfargument name="stProperties" type="struct" required="true" />
		
		<cfset var loopDate = arguments.stProperties.startDate />
		<cfset var counter = 0 />
		<cfset var aRecurringDates = arrayNew(1) />
		
		<!--- 
		yyyy: Year (et år)
		m: Month (en måned)
		d: Day (en dag)
		ww: Week (en uke)
		--->
		<cfloop from="1" to="100" index="i">
			<cfset counter = counter + 1 />
			<cfset loopDate = dateAdd(arguments.stProperties.recurringSetting, counter, arguments.stProperties.startDate) />
			<cfif isDate(arguments.stProperties.recurringEndDate) AND dateCompare(loopDate, arguments.stProperties.recurringEndDate, 'd') GTE 1>
				<!--- TODO: Oppdater recurringEndDate hvis den ikke er lik siste loopDate --->
				<cfbreak />
			</cfif>
			<cfset arrayAppend(aRecurringDates, "#loopDate#") />
		</cfloop>
		
		<!--- TODO: Fjern DEBUG --->
		<cfset application.aRecurringDates = aRecurringDates />
		
	</cffunction>
	
	<cffunction name="updateChilds" access="public" output="true" returntype="struct">
		<cfargument name="stProperties" type="struct" required="true" />
		<cfset var loopDate = arguments.stProperties.startDate />
		<cfset var counter = 0 />
		<cfset var aRecurringDates = arrayNew(1) />
		<cfset var bHasChilds = application.fapi.getContentObjects(typename="dmEvent", masterID=arguments.stProperties.objectID).recordCount />
		<cfdump var="#arguments#" />
		<!--- MASTER
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- Only run on events that are set to recurring and when status change from draft to approved --->
		<cfif (arguments.stProperties.recurringSetting IS NOT "") AND
			  (arguments.previousStatus IS "draft" AND arguments.stProperties.status IS 'approved')>
			<!--- 
			yyyy: Year (et år)
			m: Month (en måned)
			d: Day (en dag)
			ww: Week (en uke)
			--->
			<!--- TODO: Sjekk om datoen har flyttet på seg, hvis den har det må man kjøre dateAdd på alle child elementer --->
			<!--- TODO: Slett alle fremtidige, må endre på master sin recurringEndDate --->
			
			<!--- TODO: Kalkuler hva recurringEndDate er hvis den ikke er satt --->
			
			<!--- TODO: Loop helt til loopDate er større enn recurringEndDate, eller maks 100 ganger --->
			<cfloop from="1" to="100" index="i">
				<cfset counter = counter + 1 />
				<cfset loopDate = dateAdd(arguments.stProperties.recurringSetting, counter, arguments.stProperties.startDate) />
				<cfif isDate(arguments.stProperties.recurringEndDate) AND dateCompare(loopDate, arguments.stProperties.recurringEndDate, 'd') GTE 1>
					<!--- TODO: Oppdater recurringEndDate hvis den ikke er lik siste loopDate --->
					<cfbreak />
				</cfif>
				<cfset arrayAppend(aRecurringDates, "#loopDate#") />
				<cfoutput>#lsDateFormat(loopDate, "dd. mmmm yyyy")# - #lsDateFormat(loopDate, "dddd")#<br/></cfoutput>
			</cfloop>
			
			<cfdump var="#aRecurringDates#" />
			<cfabort />
		</cfif>
		
		<!--- CHILD
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- TODO: Sjekk om denne tilhører et master object, hvis det er endringer på dato skal masterID fjernes, det samme med  --->
		
		<cfset stSuper = super.afterSave(stProperties=arguments.stProperties) />
		
		<cfreturn stSuper />
	</cffunction>
	
	
	
	
	
	
	<cffunction name="updateSiblings" access="public" output="true" returntype="struct">
		<cfargument name="stProperties" type="struct" required="true" />
		<cfset var loopDate = arguments.stProperties.startDate />
		<cfset var counter = 0 />
		<cfset var aRecurringDates = arrayNew(1) />
		<cfset var bHasChilds = application.fapi.getContentObjects(typename="dmEvent", masterID=arguments.stProperties.objectID).recordCount />
		<cfdump var="#arguments#" />
		<!--- MASTER
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- Only run on events that are set to recurring and when status change from draft to approved --->
		<cfif (arguments.stProperties.recurringSetting IS NOT "") AND
			  (arguments.previousStatus IS "draft" AND arguments.stProperties.status IS 'approved')>
			<!--- 
			yyyy: Year (et år)
			m: Month (en måned)
			d: Day (en dag)
			ww: Week (en uke)
			--->
			<!--- TODO: Sjekk om datoen har flyttet på seg, hvis den har det må man kjøre dateAdd på alle child elementer --->
			<!--- TODO: Slett alle fremtidige, må endre på master sin recurringEndDate --->
			
			<!--- TODO: Kalkuler hva recurringEndDate er hvis den ikke er satt --->
			
			<!--- TODO: Loop helt til loopDate er større enn recurringEndDate, eller maks 100 ganger --->
			<cfloop from="1" to="100" index="i">
				<cfset counter = counter + 1 />
				<cfset loopDate = dateAdd(arguments.stProperties.recurringSetting, counter, arguments.stProperties.startDate) />
				<cfif isDate(arguments.stProperties.recurringEndDate) AND dateCompare(loopDate, arguments.stProperties.recurringEndDate, 'd') GTE 1>
					<!--- TODO: Oppdater recurringEndDate hvis den ikke er lik siste loopDate --->
					<cfbreak />
				</cfif>
				<cfset arrayAppend(aRecurringDates, "#loopDate#") />
				<cfoutput>#lsDateFormat(loopDate, "dd. mmmm yyyy")# - #lsDateFormat(loopDate, "dddd")#<br/></cfoutput>
			</cfloop>
			
			<cfdump var="#aRecurringDates#" />
			<cfabort />
		</cfif>
		
		<!--- CHILD
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////// --->
		<!--- TODO: Sjekk om denne tilhører et master object, hvis det er endringer på dato skal masterID fjernes, det samme med  --->
		
		<cfset stSuper = super.afterSave(stProperties=arguments.stProperties) />
		
		<cfreturn stSuper />
	</cffunction>
	
</cfcomponent>