<cfcomponent output="false" hint="Detect browser capabilities from user agent string from CGI using browscap.ini">
	<cfset $initBrowseCap()>

	<cffunction name="init">
		<cfscript>
			THIS.version = "1.1.8";
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="$initBrowseCap" mixin="controller" hint="Initializes application variables used to generate browser capabilities.">
		<cfscript>
			var loc = {};

			if ( StructKeyExists(application, "$wheels") ) {
				loc.wheels = application.$wheels;
			} else {
				loc.wheels = application.wheels;
			}
			
			$setBrowserCaps( $iniToStruct( expandPath( "#loc.wheels.pluginPath#/browsecap/assets/browscap.ini" ) ) );
			$setBrowserCapsCount( structCount( $getBrowserCaps() ) );
			$setAgentStringPatterns( $sortArrayByLen( structKeyArray( $getBrowserCaps() ), "desc" ) );
			$setAgentRegexs( $convertPatternToRegex( $getAgentStringPatterns() ) );
		</cfscript>
	</cffunction>

	<cffunction name="$setBrowserCaps" returntype="void" access="private">
		<cfargument name="browserCaps" type="struct">
		<cfset application.browsecap.browserCaps = ARGUMENTS.browserCaps>
	</cffunction>
	<cffunction name="$getBrowserCaps" returntype="struct">
		<cfreturn application.browsecap.browserCaps>
	</cffunction>

	<cffunction name="$setBrowserCapsCount" returntype="void" access="private">
		<cfargument name="browserCapsCount" type="numeric">
		<cfset application.browsecap.browserCapsCount = ARGUMENTS.browserCapsCount>
	</cffunction>
	<cffunction name="$getBrowserCapsCount" returntype="numeric">
		<cfreturn application.browsecap.browserCapsCount>
	</cffunction>

	<cffunction name="$setAgentStringPatterns" returntype="void" access="private">
		<cfargument name="agentStringPatterns" type="array">
		<cfset application.browsecap.agentStringPatterns = ARGUMENTS.agentStringPatterns>
	</cffunction>
	<cffunction name="$getAgentStringPatterns" returntype="array">
		<cfreturn application.browsecap.agentStringPatterns>
	</cffunction>

	<cffunction name="$setAgentRegexs" returntype="void" access="private">
		<cfargument name="agentRegexs" type="array">
		<cfset application.browsecap.agentRegexs = ARGUMENTS.agentRegexs>
	</cffunction>
	<cffunction name="$getAgentRegexs" returntype="array">
		<cfreturn application.browsecap.agentRegexs>
	</cffunction>

	<cffunction name="$iniToStruct" returntype="struct" access="private">
		<cfargument type="string" required="true" name="iniFilePath">
		<cfscript>
			var data = {};
			var file = fileOpen( ARGUMENTS.iniFilePath );
			var line = '';
			var lineLen = '';

			while ( !fileIsEOF( file ) ) {
				line = FileReadLine( file );
				lineLen = len( line );

				if ( lineLen > 0 ) {
					switch ( left( line, 1 ) ) {
						case ";" :
							continue;
							break;
						case "[" :
							section = mid( line, 2, lineLen - 2 );
							break;
						default:
							data[section][listFirst( line, "=" )] = listRest( line, "=" );
					}
				}
			}
			fileClose( file );
			return data;
		</cfscript>
	</cffunction>

	<cffunction name="$convertPatternToRegex" returntype="array" access="private">
		<cfargument name="agentStringPatterns" type="array" required="true">
		<cfscript>
			var returnArray = [];
			for (var i = 1; i <= arrayLen( ARGUMENTS.agentStringPatterns ); i++) {
					var regex = left( ARGUMENTS.agentStringPatterns[i], 1 ) != "*" ? "^" : "";

					regex &= replaceList( ARGUMENTS.agentStringPatterns[i], ".,*,?,(,),[,]", "\.,.*,.,\(,\),\[,\]" );

					if ( right( ARGUMENTS.agentStringPatterns[i], 1 ) != "*" )
						regex &= "$";
				returnArray[i] = regex;
				//ARGUMENTS.agentStringPatterns[i] = regex;
			}
			return returnArray;
		</cfscript>
	</cffunction>

	<cffunction name="$sortArrayByLen" returntype="array" access="private">
		<cfargument name="strings" type="array" required="true">
		<cfargument name="order" type="string" default="asc">
		<cfscript>
			var results = [];
			var LOCAL = {};
			for (var i = 1; i <= arrayLen(ARGUMENTS.strings); i++)
				local.lengths[i] = len(ARGUMENTS.strings[i]);

			var sortedIndices = structSort(lengths, "numeric", ARGUMENTS.order);

			LOCAL.iter = sortedIndices.iterator();
			while(LOCAL.iter.hasNext()) {
				LOCAL.el = LOCAL.iter.next();
				arrayAppend(results, ARGUMENTS.strings[LOCAL.el]);
			}

			return results;
		</cfscript>
	</cffunction>

	<cffunction name="getBrowserCap">
		<cfargument name="userAgent" type="string" required="true" default="#CGI.HTTP_USER_AGENT#">
		<cfscript>
			// find the longest matched agent, since agent is sorted by len desc, first agent is sufficient 
			var matchedIndex = 1;

			while ( matchedIndex < THIS.$getBrowserCapsCount() && !reFindNoCase( THIS.$getAgentRegexs()[matchedIndex], ARGUMENTS.userAgent ) )
				++matchedIndex;

			var matchedStringPattern = THIS.$getAgentStringPatterns()[matchedIndex];
			var result = {};

			structAppend( result, THIS.$getBrowserCaps()[matchedStringPattern] );

			// Fetch the rest of the info from parent(s)
			while ( structKeyExists( result, "parent" ) ) {
				var parentAgent = result.parent;
				structDelete( result, "parent" );
				structAppend( result, THIS.$getBrowserCaps()[parentAgent], false );
			}

			return result;
		</cfscript>
	</cffunction>

</cfcomponent>
