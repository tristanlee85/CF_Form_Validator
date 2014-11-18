<!---
	@author		Drew Dulgar / Tristan Lee
	@date		10/12/09
	@purpose	Class used for validating form fields
	@changlog	3/28/10		Converted from ColdBox plugin to basic CFC
				5/04/10		Added function to set look-up values from a query
				
	ROUTINE EXAMPLES
	   - (!) indicates the routine naturally supports negation
	----------------
	> required :: requires the field
	> required[fieldName] :: requires the field if 'fieldName' has any value
	> required[fieldName=value] :: requires the field if 'fieldName' has a value of 'value'
	> (!)matches[fieldName] :: field must match 'fieldName'
	> alpha :: field must only contain alpha characters
	> alpha_dash :: field must only contain alpha and hyphen characters
	> alpha_numeric :: field must only contain alphanumeric characters
	> between[value1|value2] :: field must be between the values specified in the argument list (delimited by a pipe)
	> contains[value] :: field must contains 'value'
	> does_not_contain[value] :: field must not contain 'value'
	> equals[value] :: field must equal 'value'
	> exact_length[len] :: field must have a exact length of 'len'
	> greater_than[fieldName] :: field must be greater than the value of the field 'fieldName'
	> greater_than[value] :: field must be greater than 'value'
	> greater_than_datetime[fieldName] :: field must have a date greather than the value of the field 'fieldName'
	> greater_than_datetime[value] :: field must have a date greater than 'value'
	> greater_than_or_equal_to[fieldName] :: field must be greater than or equal to the value of the field 'fieldName'
	> greater_than_or_equal_to[value] :: field must be greater than or equal to 'value'
	> greater_than_or_equal_to_datetime[fieldName] :: field must have a date greater than or equal to the value of the field 'fieldName'
	> greater_than_or_equal_to_datetime[value] :: field must have a date greater than or equal to 'value'
	> integer :: field must be an interger
	> is_empty[fieldName|fieldName1|fieldNameN...] :: at least one of the fields specified in the argument list (delimited by a pipe) must have a value
	> is_natural :: field must be a natural number
	> is_natural_no_zero :: field must be a natural number, excluding 0
	> less_than[fieldName] :: field must be less than the value of the field 'fieldName'
	> less_than[value] :: field must be less than 'value'
	> less_than_datetime[fieldName] :: field must have a date less than the value of the field 'fieldName'
	> less_than_datetime[value] :: field must have a date less than 'value'
	> less_than_or_equal_to[fieldName] :: field must be less than or equal to the value of the field 'fieldName'
	> less_than_or_equal_to[value] :: field must be less than or equal to 'value'
	> less_than_or_equal_to_datetime[fieldName] :: field must have a date less than or equal to the value of the field 'fieldName'
	> less_than_or_equal_to_datetime[value] :: field must have a date less than or equal to 'value'
	> lookup_value[lookup] :: field must be one of the values in the specified 'lookup'
	> max_decimal[precision|scale] :: field must be a decimal no larger than the specified 'precision' and 'scale'
	> max_length[len] :: field must have a maximum length of 'len'
	> min_length[len] :: field must have a minimum length of 'len'
	> numeric :: field must be a numeric value
	> select_at_least[value] :: number of field values (delimited by a comma) must be at least 'value'
	> select_no_more_than[value] :: number of field values (delimited by a comma) must be no more than 'value'
	> valid_base64 :: field must be of valid base64 representation
	> valid_creditcard :: field must be of valid creditcard format
	> valud_currencyUS :: field must be of valid US currency format
	> valid_date :: field must be of valid US date format
	> valid_email :: field must be of valid e-mail address format
	> valid_email_list :: list of field values must be of valid e-mail address format
	> valid_ip :: field must be of valid IPv4 address format
	> valid_pdf[filepath] :: 'filepath' must be a path to a PDF file
	> valid_phoneUS :: field must be of valid US phone number format
	> valid_postal :: field must be of valid postal code format for US and Canada
	> valid_ssn :: field must be of valid SSN format
	> valid_time :: field must be of valid time format
	> valid_url :: field must be of valid URL format
	> value_is_one_of[value|value1|valueN...] :: field must be one of the values specified in the argument list (delimited by a pipe)
--->

<cfcomponent name="FormValidator" output="false">

	<!--- Private members ---> 
	<cfset variables.lookups = {}>
	<cfset variables.validation = {}>
	<cfset variables.validation_order = []>
	<cfset variables.errors = []>
	<cfset variables.errorFields = []>
	<cfset variables.rc = {}>
	<cfset variables.run = false>
	<cfset variables.trigger = {}>
	<cfset variables.interceptionMethods = {}>
	
	<!--- Static list of CFCs to automatically import on instantiation --->
	<cfset variables.importCFCs = [] />

	<cfset variables.settings = {}>
	<cfset variables.settings.returnSelectors = true>
	<cfset variables.settings.persistDefaultValue = false>
	<cfset variables.settings.errors = {}>
	<cfset variables.settings.errors.unique = {}>
	<cfset variables.settings.errors['required'] = 'The field [LABEL] is required.'>
	<cfset variables.settings.errors['matches'] = 'The [LABEL] field does not match the [ARGUMENT] field.'>
    <cfset variables.settings.errors['!matches'] = 'The [LABEL] field can not match the [ARGUMENT] field.'>
	<cfset variables.settings.errors['min_length'] = 'The [LABEL] field must be at least [ARGUMENT] character(s).'>
	<cfset variables.settings.errors['max_length'] = 'The [LABEL] field must be at most [ARGUMENT] character(s).'>
	<cfset variables.settings.errors['exact_length'] = 'The [LABEL] field must be exactly [ARGUMENT] characters(s).'>
	<cfset variables.settings.errors['greater_than'] = 'The [LABEL] field must be greater than [ARGUMENT].'>
    <cfset variables.settings.errors['greater_than_datetime'] = 'The [LABEL] field must be after [ARGUMENT_VALUE].'>
    <cfset variables.settings.errors['greater_than_or_equal_to'] = 'The [LABEL] field must be greater than or equal to [ARGUMENT].'>
    <cfset variables.settings.errors['greater_than_or_equal_to_datetime'] = 'The [LABEL] field must be on or after [ARGUMENT_VALUE].'>
	<cfset variables.settings.errors['less_than'] = 'The [LABEL] field must be less than [ARGUMENT].'>
    <cfset variables.settings.errors['less_than_datetime'] = 'The [LABEL] field must be before [ARGUMENT_VALUE].'>
    <cfset variables.settings.errors['less_than_or_equal_to'] = 'The [LABEL] field must be less than or equal to [ARGUMENT].'>
    <cfset variables.settings.errors['less_than_or_equal_to_datetime'] = 'The [LABEL] field must be on or before [ARGUMENT_VALUE].'>
	<cfset variables.settings.errors['select_at_least'] = 'Select at least [ARGUMENT] items for the [LABEL] field.'>
	<cfset variables.settings.errors['select_no_more_than'] = 'Select no more than [ARGUMENT] items for the [LABEL] field.'>
	<cfset variables.settings.errors['contains'] = 'The [LABEL] field must contain the value [ARGUMENT].'>
	<cfset variables.settings.errors['does_not_contain'] = 'The [LABEL] field should not contain the [ARGUMENT] field.'>
	<cfset variables.settings.errors['valid_email'] = 'The [LABEL] field is not a valid email.'>
	<cfset variables.settings.errors['alpha'] = 'The [LABEL] field can only be alpha characters.'>
	<cfset variables.settings.errors['alpha_numeric'] = 'The [LABEL] field can only be alpha numeric characters and numbers.'>
	<cfset variables.settings.errors['alpha_dash'] = 'The [LABEL] field can only contain alpha numeric characters, underscores, and dashes.'>
	<cfset variables.settings.errors['numeric'] = 'The [LABEL] field must be numeric.'>
	<cfset variables.settings.errors['integer'] = 'The [LABEL] field must be an integer.'>
	<cfset variables.settings.errors['is_natural'] = 'The [LABEL] field must be a natural number.'>
	<cfset variables.settings.errors['is_natural_no_zero'] = 'The [LABEL] must be a natural number greater than 0.'>
	<cfset variables.settings.errors['valid_base64'] = 'The [LABEL] field must be a valid base64 string.'>
	<cfset variables.settings.errors['is_valid_value'] = 'The [LABEL] field does not match the [ARGUMENT] field.'>
	<cfset variables.settings.errors['value_is_one_of'] = 'The [LABEL] field does contain one of the values in [ARGUMENT].'>
	<cfset variables.settings.errors['lookup_value'] = 'The [LABEL] field does not have a valid value.'>
	<cfset variables.settings.errors['valid_url'] = 'The [LABEL] field must be a valid url.'>
	<cfset variables.settings.errors['valid_ip'] = 'The [LABEL] field must be a valid ip address.'>
	<cfset variables.settings.errors['valid_ssn'] = 'The [LABEL] field is not a valid social security number.'>
	<cfset variables.settings.errors['valid_postal'] = 'The [LABEL] field is not a valid postal address.'>
    <cfset variables.settings.errors['valid_date'] = 'The [LABEL] field is not a valid date.'>
	<cfset variables.settings.errors['valid_time'] = 'The [LABEL] field is not a valid time.'>
	<cfset variables.settings.errors['valid_phoneUS'] = 'The [LABEL] field is not a valid phone number.'>
	<cfset variables.settings.errors['valid_currencyUS'] = 'The [LABEL] is not a valid currency amount.'>
	<cfset variables.settings.errors['valid_creditcard'] = 'The [LABEL] field is not a valid credit card number.'>
	<cfset variables.settings.errors['valid_file'] = 'The [LABEL] field does not contain a valid file type.'>
	<cfset variables.settings.errors['between'] = 'The [LABEL] field must be between [ARGUMENT] characters.'>


	<cfset variables.mimeTypes = {}>

	<cffunction name="init" access="public" returntype="FormValidator" output="false" hint="Pass in as many structures for values as you want. First passed in structure takes precedence over the next. First come First Serve.">
		<cfargument name="collection" required="true" type="struct" >

		<cfset var local = structNew()>

		<cfset variables.rc = arguments.collection>

		<cfset structDelete(arguments, 'collection')>

		<cfif NOT structIsEmpty(arguments)>
			<cfloop collection="#arguments#" item="local.key">
				<cfset structAppend(variables.rc, arguments[local.key])>
			</cfloop>
		</cfif>

		<!--- clean all the values as needed --->
		<cfloop collection="#variables.rc#" item="local.key">
			<cfif isSimpleValue(variables.rc[local.key])>
				<cfset variables.rc[local.key] = trim(variables.rc[local.key])>
			</cfif>
		</cfloop>
		
		<!--- Import CFC methods --->
		<cfloop array="#variables.importCFCs#" index="local.cfcName">
			<cfset importRoutines(local.cfcName) />
		</cfloop>

		<!--- Return instance --->
		<cfreturn this>
	</cffunction>

	<cffunction name="getValue" access="public" returntype="string" output="false">
		<cfargument name="item" type="string" required="true">
		<cfargument name="default" type="string" required="true" default="">

		<cfif structKeyExists(variables.rc, arguments.item)>
			<cfreturn variables.rc[arguments.item]>
		<cfelse>
			<cfreturn arguments.default>
		</cfif>
	</cffunction>

	<cffunction name="getMimeType" access="public" returntype="array" output="false">
		<cfargument name="ext" type="string" required="true">

		<cfif structKeyExists(variables.mimeTypes, ext)>
			<cfreturn listToArray(variables.mimeTypes[ext])>
		</cfif>

		<cfreturn []>
	</cffunction>

	<cffunction name="setReturnSelectors" access="public" returntype="void" output="false">
		<cfargument name="value" type="string" required="true" default="boolean">

		<cfswitch expression="#arguments.value#">
			<cfcase value="boolean">
				<cfset variables.settings.returnSelectors = false>
			</cfcase>

			<cfcase value="text">
				<cfset variables.settings.returnSelectors = true>
			</cfcase>

			<cfdefaultcase>
				<cfset variables.settings.returnSelectors = false>
			</cfdefaultcase>
		</cfswitch>
	</cffunction>

	<cffunction name="setTrigger" access="public" returntype="void" output="false">
		<cfargument name="name" type="string" required="true">
		<cfargument name="value" type="string" required="false" default="">

		<cfset variables.trigger.name = arguments.name>
		<cfset variables.trigger.value = arguments.value>

	</cffunction>

	<cffunction name="setMethod" access="public" returntype="void" output="false">
		<cfargument name="name" required="true" type="string">
		<cfargument name="method" required="true" type="any">
        <cfargument name="message" required="false" type="string" />

		<cfset variables[arguments.name] = arguments.method>
        
        <cfif structKeyExists(arguments, "message") && len(trim(arguments.message)) GT 0>
        	<cfset setErrorMessage(arguments.name, arguments.message) />
        </cfif>        
	</cffunction>

	<cffunction name="setPreValidation" access="public" returntype="void" output="false"
    			hint="Executes before all form fields get validated.">
		<cfargument name="function" required="true" type="any">

		<cfset variables.interceptionMethods['preInterception'] = arguments.function>

	</cffunction>

	<cffunction name="setPostValidation" access="public" returntype="void" output="false"
    			hint="Eexecutes after all form fields get validated.">
		<cfargument name="function" required="true" type="any">

		<cfset variables.interceptionMethods['postInterception'] = arguments.function>

	</cffunction>

	<cffunction name="setLookupValue" access="public" returntype="void" output="false">
		<cfargument name="name" type="string" required="true">
		<cfargument name="key" type="any" required="true">
		<cfargument name="value" type="any" required="false" default="">

		<cfset local = {}>

		<cfset local.key = arguments.key>
		<cfset local.value = arguments.value>

		<cfif len(trim(local.value)) EQ 0>
			<cfset local.value = local.key>
		</cfif>

		<cfif NOT structKeyExists(variables.lookups, arguments.name)>
			<cfset variables.lookups[arguments.name] = []>
		</cfif>

		<cfset arrayAppend(variables.lookups[arguments.name], local)>

	</cffunction>

	<cffunction name="setLookupValuesFromQuery" access="public" returntype="void" output="false">
		<cfargument name="query" type="query" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="key" type="string" required="true">
		<cfargument name="value" type="any" required="false" default="">

		<cfloop query="arguments.query">
			<cfset setLookupValue(arguments.name, arguments.query[arguments.key], arguments.query[arguments.value])>
		</cfloop>

	</cffunction>

	<cffunction name="getLookup" access="public" returntype="array" output="false">
		<cfargument name="name" type="string" required="true">

		<cfif structKeyExists(variables.lookups, arguments.name)>
			<cfreturn variables.lookups[arguments.name]>
		</cfif>

		<cfreturn []>

	</cffunction>

	<cffunction name="setValidation" access="public" returntype="void" output="false">
		<cfargument name="name" required="true" type="string">
		<cfargument name="label" required="false" type="string">
		<cfargument name="validation" required="false" type="string">

		<cfif arguments.label EQ ''>
			<cfset arguments.label = arguments.name>
		</cfif>

		<cfif structKeyExists(variables.validation, arguments.name)>
			<cfset variables.validation[arguments.name].validators = variables.validation[arguments.name].validators & ',' & arguments.validation>
		<cfelse>
			<cfset arrayAppend(variables.validation_order, arguments.name)>
			<cfset variables.validation[arguments.name] = {}>
			<cfset variables.validation[arguments.name].label = arguments.label>
			<cfset variables.validation[arguments.name].validators = arguments.validation>
		</cfif>

	</cffunction>

	<cffunction name="getValidation" access="public" returntype="struct" output="false">
		<cfreturn variables.validation />
	</cffunction>
    
    <cffunction name="getLabel" access="public" returntype="string" output="false">
    	<cfargument name="field" type="string" required="true" />
        
        <cfif structKeyExists(variables.validation, arguments.field) AND structKeyExists(variables.validation[arguments.field], "label")>
        	<cfreturn variables.validation[arguments.field].label />
        </cfif>
        
        <cfreturn "" />
    </cffunction>

	<cffunction name="run" access="public" returntype="boolean" output="false">
		<cfargument name="runWithoutTrigger" type="boolean" default="false" />
        
		<cfset var local = {}>
		<cfset variables.run = false>

		<cfif 	arguments.runWithoutTrigger OR
				(
					structKeyExists(variables.trigger, 'name') AND
					structKeyExists(variables.trigger, 'value') AND 
					(
						structKeyExists(variables.rc, variables.trigger.name) AND
						variables.trigger.value EQ ''
					)
				)
				OR 
				(
					variables.trigger.value NEQ ''
					AND structKeyExists(variables.rc, variables.trigger.name)
					AND variables.rc[variables.trigger.name] EQ variables.trigger.value
				)>

			<cfset variables.run = true>

			<cfif structKeyExists(variables.interceptionMethods, 'preInterception')>
				<cfset variables.interceptionMethods.preInterception() />
			</cfif>

			<cfloop from="1" to="#arrayLen(variables.validation_order)#" index="local.i">
				<cfset validateField(	variables.validation_order[local.i],
										variables.validation[variables.validation_order[local.i]].validators,
										variables.validation[variables.validation_order[local.i]].label)>
			</cfloop>


			<cfif structKeyExists(variables.interceptionMethods, 'postInterception')>
				<cfset variables.interceptionMethods.postInterception() />
			</cfif>
		</cfif>

		<cfreturn validated()>
	</cffunction>

	<cffunction name="getErrors" access="public" returntype="array" output="false">
    
    	<cfset var local = structNew() />
        
		<cfreturn variables.errors>
	</cffunction>
    
    <cffunction name="totalErrors" access="public" returntype="numeric" output="false">
    	<cfset var local = structNew() />
        
        <cfreturn arrayLen(getErrors()) />
    </cffunction>

	<cffunction name="displayErrors" access="public" returntype="string" output="false">
		<cfargument name="prepend" default="<li>" required="no" type="string">
		<cfargument name="append" default="</li>" required="no" type="string">

		<cfset var local = {}>

		<cfset local.error = ''>

		<cfif NOT validated()>

			<cfset local.errors = getErrors()>

			<cfloop from="1" to="#ArrayLen(local.errors)#" index="local.i">
				<cfset local.error = local.error & arguments.prepend & local.errors[local.i] & arguments.append>
			</cfloop>
		</cfif>

		<cfreturn local.error>
	</cffunction>

	<cffunction name="validated" access="public" returntype="boolean" output="false">

		<cfif variables.run EQ 0 OR ArrayLen(variables.errors) GT 0>
			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction>


	<cffunction name="getDefaultValue" output="false" returntype="string" access="private">
		<cfargument name="field" default="" required="true" type="string">
		<cfargument name="default" default="" required="true" type="string">


		<cfif variables.run EQ 0 OR variables.settings.persistDefaultValue EQ 1>
			<cfreturn arguments.default>
		<cfelseif structKeyExists(variables.rc, arguments.field)>
			<cfreturn variables.rc[arguments.field]>
		</cfif>

		<cfreturn ''>

	</cffunction>


	<cffunction name="setValue" output="false" returntype="string" access="public">
		<cfargument name="field" default="" required="true" type="string">
		<cfargument name="default" default="" required="false" type="string">

		<cfreturn getDefaultValue(arguments.field, arguments.default)>

	</cffunction>

	<cffunction name="setSelect" output="false" returntype="any" access="public">
		<cfargument name="field" default="" required="true" type="string">
		<cfargument name="value" default="" required="true" type="string">
		<cfargument name="default" default="" required="false" type="string">

		<cfset var local = {}>

		<cfset local.value = getDefaultValue(arguments.field, arguments.default)>

		<cfif listFindNoCase(local.value, arguments.value)>
			<cfif variables.settings.returnSelectors EQ true>
				<cfreturn ' selected="selected"'>
			<cfelse>
				<cfreturn true>
			</cfif>
		<cfelseif variables.settings.returnSelectors EQ false>
			<cfreturn false>
		</cfif>

	</cffunction>

	<cffunction name="setRadio" output="false" returntype="string" access="public">
		<cfargument name="field" default="" required="true" type="string">
		<cfargument name="value" default="" required="true" type="string">
		<cfargument name="default" default="" required="false" type="string">

		<cfset var local = {}>

		<cfset local.value = getDefaultValue(arguments.field, arguments.default)>

		<cfif listFindNoCase(local.value, arguments.value)>
			<cfif variables.settings.returnSelectors EQ true>
				<cfreturn ' checked="checked"'>
			<cfelse>
				<cfreturn true>
			</cfif>
		<cfelseif variables.settings.returnSelectors EQ false>
			<cfreturn false>
		</cfif>


	</cffunction>

	<cffunction name="setCheckbox" output="false" returntype="string" access="public">
		<cfargument name="field" default="" required="true" type="string">
		<cfargument name="value" default="" required="true" type="string">
		<cfargument name="default" default="" required="false" type="string">

		<cfset var local = {}>

		<cfset local.value = getDefaultValue(arguments.field, arguments.default)>

		<cfif listFindNoCase(local.value, arguments.value)>
			<cfif variables.settings.returnSelectors EQ true>
				<cfreturn ' checked="checked"'>
			<cfelse>
				<cfreturn true>
			</cfif>
		<cfelseif variables.settings.returnSelectors EQ false>
			<cfreturn false>
		</cfif>


	</cffunction>


	<cffunction name="validateField" output="false" returntype="boolean" access="private">
		<cfargument name="field" default="" required="true" type="string">
		<cfargument name="validations" default="" required="false" type="string">
		<cfargument name="label" default="" required="false" type="string">

		<cfset var local = {}>
		
        <!--- pass if we have no validations for this field --->
		<cfif trim(arguments.validations) EQ ''>
			<cfreturn true>
		</cfif>
		
        <!--- get the value of this field --->
		<cfset local.value = getValue(arguments.field) />
		
        <!--- find either 'routine_name' OR 'routine_name[arguments]' --->
        <cfset local.searchRegex = '(\!)?([^\[\],]+)(?:\[([^\]]*)\])?' />	
		
		<cfset local.pattern = createObject("java", "java.util.regex.Pattern").compile(local.searchRegex) />
		<cfset local.matcher = local.pattern.matcher(arguments.validations) />
		<cfset local.arValidation = [] />
		
		<!--- iterate the matches, creating a structure of items for each validation specified --->
		<cfloop condition="#local.matcher.find()#">
			<cfset local.thisValidation = {negates = local.matcher.group(1), routine = local.matcher.group(2), arguments = local.matcher.group(3), validation = local.matcher.group()} />
            
            <!--- --->
            <cfif (structkeyExists(local.thisValidation, "negates") && local.thisValidation.negates EQ "!")>
            	<cfset local.thisValidation.negates = true />
            <cfelse>
            	<cfset local.thisValidation.negates = false />
            </cfif>
			
			<!--- no arguments exist for this routine, so set it as an empty string --->
			<cfif !structkeyExists(local.thisValidation, "arguments")>
				<cfset local.thisValidation.arguments = "" />
			</cfif>
			
			<!--- the 'required' routine should always be first to execute to prepend it to the array --->
			<cfif local.thisValidation.routine EQ "required">
				<cfset arrayPrepend(local.arValidation, local.thisValidation) />
			<cfelse>
				<cfset arrayAppend(local.arValidation, local.thisValidation) />
			</cfif>
		</cfloop>
		
		<!--- if no 'required' (without conditions) routine is specified,
			  and the field doesn't have a value, there's nothing to validation --->
		<cfif arrayLen(local.arValidation) GT 0 &&
			  local.arValidation[1].routine NEQ "required" &&
			  len(local.arValidation[1].arguments) EQ 0 &&
			  local.value EQ "">
			<cfreturn true />
		</cfif>
        
		<!--- Loop all of the validation routines and test the field for validity --->
		<cfloop array="#local.arValidation#" index="local.validation">
        
            <!--- execute our validation method and set our status based on it. --->
			<cfif isDefined("#trim(local.validation.routine)#")>
				<cfinvoke 	method 			= "#local.validation.routine#"
							value 			= "#local.value#"
							argument		= "#local.validation.arguments#"
							field			= "#arguments.field#"
							returnvariable	= "local.test">

				<cfif	(
							local.validation.routine EQ "required"
							OR len(local.value) GT 0
							OR NOT structKeyExists(variables.rc, arguments.field)
						) 
						<!---AND	(NOT local.test AND NOT local.validation.negates)--->
						
						AND ((local.validation.negates && local.test) || (!local.validation.negates && !local.test))
						>

					<cfset setError(local.validation.routine, arguments.field, local.validation.arguments, local.value, local.validation.negates)>
					<cfreturn false>
				</cfif>
			<cfelse>
				<cfthrow type="custom" message="Validation Routine #local.validation.routine# Does Not Exist" extendedinfo="The #local.validation.routine# validation routine method does not exist. It was set on the field #arguments.field#. Please check to make sure the method exists and that its name is spelled correctly.">
			</cfif>
        </cfloop>        

		<cfreturn true>
	</cffunction>

	<!--- set a validation methods global error message (ie any field ) --->
	<cffunction name="setErrorMessage" output="false" access="public" returntype="void">
		<cfargument name="method" required="true" type="string">
		<cfargument name="message" required="false" default="" type="string">

		<cfset variables.settings.errors[arguments.method] = arguments.message>
	</cffunction>


	<!--- set a validation methods error message specific to a field --->
	<cffunction name="setFieldErrorMessage" output="false" access="public" returntype="void">
		<cfargument name="field" required="true" type="string">
		<cfargument name="method" required="true" type="string">
		<cfargument name="message" required="false" default="" type="string">

		<cfset variables.settings.errors.unique[arguments.field][arguments.method] = arguments.message>

	</cffunction>

	<!--- set and add an error message based on the given field and the fields specific error message --->
	<cffunction name="setError" output="false" access="public" returntype="void">
		<cfargument name="method" required="true" type="string">
		<cfargument name="field" required="true" type="string">
		<cfargument name="argument" required="false" default="" type="string">
		<cfargument name="value" required="false" type="string">
        <cfargument name="negates" required="false" type="boolean" default="false">
        
		<cfset var local = {}>

		<cfif arguments.negates>
        	<cfset arguments.method = "!#arguments.method#" />
        </cfif>
        
		<cfset local.label = 'Label not set'>
		<cfset local.message = getErrorMessage(arguments.field, arguments.method)>

        <!--- in case the argument has multiple values, get just the first --->
        <cfset arguments.argument = getToken(arguments.argument, 1, '|') />

		<!--- get the label for this field --->
		<cfif structKeyExists(variables.validation, arguments.field)>
			<cfset local.label = variables.validation[arguments.field].label>
		</cfif>

		<cfset local.message = Replace(local.message, '[LABEL]', local.label, 'all')>
        
        <!--- is the argument field an actual field passed to us for validation? --->
        <cfset local.argLabel = getLabel(arguments.argument) />
        <cfif structKeyExists(variables.rc, arguments.argument) && local.argLabel NEQ "">
        	<cfset local.message = Replace(local.message, '[ARGUMENT_VALUE]', variables.rc[arguments.argument], 'all') />
        	<cfset local.message = Replace(local.message, '[ARGUMENT]', local.argLabel, 'all') />
        <cfelse>
			<cfset local.message = Replace(local.message, '[ARGUMENT]', arguments.argument, 'all') />
        </cfif>

		<!--- include value in the message name? --->
        <cfif structKeyExists(arguments, 'value')>
        	<cfset local.message = Replace(local.message, '[VALUE]', arguments.value, 'all') />
        </cfif> 
		
        <cfset addError(arguments.field, local.message) />

	</cffunction>
    
    <!--- add error messages to the global array --->
    <cffunction name="addError" output="false" access="public" returntype="void">
    	<cfargument name="field" required="true" type="string">
        <cfargument name="message" required="true" type="string">
        
		<cfset arrayAppend(variables.errors, {field=arguments.field, message=arguments.message})>
		<cfset arrayAppend(variables.errorFields, arguments.field) />        
        
    </cffunction>


	<cffunction name="getErrorMessage" output="false" access="private" returntype="string">
		<cfargument name="field" required="true" type="string">
		<cfargument name="method" required="false" type="string">

		<cfset var local = {}>

		<cfif structKeyExists(arguments, 'method') AND structKeyExists(variables.settings.errors.unique, arguments.field) AND structKeyExists(variables.settings.errors.unique[arguments.field], arguments.method)>
			<cfset local.message = variables.settings.errors.unique[arguments.field][arguments.method]>
		<cfelseif structKeyExists(variables.settings.errors, arguments.method)>
			<cfset local.message = variables.settings.errors[arguments.method]>
		<cfelse>
			<cfset local.message = 'Unable to locate an error message for method ' & arguments.method & ' for field: [LABEL]'>
		</cfif>

		<cfreturn local.message>
	</cffunction>

	<cffunction name="getErrorFields" output="false" access="public" returntype="array">
		<cfreturn variables.errorFields>
	</cffunction>

	<cffunction name="getFieldLabel" output="false" access="public" returntype="string">
		<cfargument name="field" required="true" type="string">

		<cfif structKeyExists(variables.validation,arguments.field) AND structKeyExists(variables.validation[arguments.field], 'label')>
			<cfreturn variables.validation[arguments.field].label>
		</cfif>

		<cfreturn ''>
	</cffunction>

	<cffunction name="importRoutines" output="true" access="public" returntype="void">
		<cfargument name="filename" required="true" type="string">

		<cfset var local = {}>
		<cfif fileExists(expandPath(arguments.filename))>
			<!--- Since we are going to include the UDF/CFC, there is a chance that
				  the syntax is malformed or the UDF already exists in scope and we
				  don't want that to throw errors and kill the whole validation. --->
			<cftry>
				<cfif listLast(getFileInfo(expandPath(arguments.filename)).name, ".") EQ "cfm">
					<!--- We don't need to call setMethod() on CFM includes as the functions are
						  automatically added to the "variables" scope.

						  ** Excluded for now since I would rather not include files without control
						     of what is being executed. **
					<cfinclude template="#arguments.filename#">--->
				<cfelseif listLast(getFileInfo(expandPath(arguments.filename)).name, ".") EQ "cfc">
					<!--- Now we create a reference to the supplied CFC, get a list of its methods,
						  and use only those that return "boolean" since that's what the validator
						  looks for. --->
					<cfset arguments.filename = replaceNoCase(arguments.filename, ".cfc", "", "all")>
					<cfset local.cfc = createObject("component", "#getComponentMetaData(arguments.filename).name#")>
					<cfset local.arMethods = getComponentMetaData(arguments.filename).functions>

					<!--- Add in the methods to this validator --->
					<cfloop array="#local.arMethods#" index="local.stcMethod">
						<cfif structKeyExists(local.cfc, local.stcMethod.name) AND local.stcMethod.returnType EQ "boolean">
							<cfset setMethod(local.stcMethod.name, local.cfc[local.stcMethod.name])>
						</cfif>
					</cfloop>
				</cfif>
				<cfcatch type="any">
					<cfrethrow />
				</cfcatch>
			</cftry>
		</cfif>
	</cffunction>

	<cffunction name="getErrorMessages" access="public" output="false" returntype="struct"
				hint="Returns a collection of all set error messsages">
		<cfset var stc = {}>
		<cfloop collection="#variables.settings.errors#" item="routine">
			<cfif isSimpleValue(variables.settings.errors[routine])>
				<cfset stc[routine] = variables.settings.errors[routine]>
			</cfif>
		</cfloop>
		<cfreturn stc>
	</cffunction>

	<cffunction name="hasErrorMessage" access="public" output="false" returntype="boolean"
				hint="Checks to see if a custom error message has been set for a specific field and routine">
		<cfargument name="routine" required="true" type="string">
		<cfargument name="field" required="true" type="string">

		<cftry>
			<cfset len(variables.settings.errors.unique[arguments.field][arguments.routine])>
			<cfreturn true>

			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- All validation routines follow. Must return true for succesful
		  validation or false for failed validation; every function gets passed the following arguments:
		  value = the value of the current field being validated
		  argument = the value passed if when setting validation a value was put in brackets ie myroutine[argument_here]
		  field = the name of the form field currently being validated --->	
	<cffunction name="required" output="false" access="public" returntype="boolean"
				hint="Requires a field, or requires is based on a target field's value">
		<cfargument name="value" required="true" type="string">
		<cfargument name="argument" required="true" type="string">
		<cfargument name="field" required="true" type="string">
		<cfset var local = {}>
		
		<!--- If no arguments were passed, just check to see if the field has a value --->
		<cfif len(trim(arguments.argument)) EQ 0>
			<cfreturn len(trim(arguments.value)) GT 0>
		</cfif>

		<cfset local.arg = trim(listFirst(arguments.argument, "="))>
		<cfset local.val = trim(listLast(arguments.argument, "="))>

		<!--- Check for requiring at least X field(s) --->
		<cfset local.doCheckAtLeast = reReplaceNoCase(local.arg, "[^a-z]", "", "all") EQ "atleast">
		<cfset local.checkAtLeast = isNumeric(reReplaceNoCase(local.arg, "\D", "", "all")) ? reReplaceNoCase(local.arg, "\D", "", "all") : 0>

		<!--- Checks that at least X of the specified fields has a value --->
		<cfif local.doCheckAtLeast && local.checkAtLeast GT 0>
			<cfset local.atLeastCount = 0>
			<cfloop list="#local.val#" index="local.j" delimiters="|">
				<cfif structKeyExists(variables.rc, local.j) && len(trim(getValue(local.j))) GT 0>
					<cfset local.atLeastCount++>
				</cfif>
			</cfloop>

			<cfif local.atLeastCount LT local.checkAtLeast>
				<cfif NOT hasErrorMessage("required", arguments.field)>
					<cfset local.fieldLabels = []>
					<cfloop list="#local.val#" index="local.k" delimiters="|">
						<cfset arrayAppend(local.fieldLabels, getFieldLabel(local.k))>
					</cfloop>
					<cfset setFieldErrorMessage(arguments.field, "required", "You must supply a value for one of the following fields: #arrayToList(local.fieldLabels, ", ")#.")>
					<cfreturn false>
				</cfif>
				<cfreturn true>
			</cfif>
		<cfelseif structKeyExists(variables.rc, local.arg)>
			<cfif listLen(arguments.argument, "=") EQ 2 AND len(trim(local.val)) GT 0>
				<cfif variables.rc[local.arg] EQ local.val AND len(trim(arguments.value)) EQ 0>
					<cfreturn false>
				</cfif>
			<cfelse>
				<cfif len(variables.rc[local.arg]) GT 0 AND len(trim(arguments.value)) EQ 0>
					<cfreturn false>
				</cfif>
			</cfif>
		</cfif>

		<cfreturn true>
	</cffunction>


	<cffunction name="matches" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="string" default="">
		<cfargument name="field" required="false" type="string" default="">
		<cfset var local = {}>

		<cfif structKeyExists(variables.rc, arguments.argument) AND variables.rc[arguments.argument] EQ arguments.value>
			<cfreturn true>
		</cfif>

		<cfreturn false>

	</cffunction>

	<cffunction name="min_length" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif len(trim(arguments.value)) GTE arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>

	</cffunction>


	<cffunction name="max_length" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif len(trim(arguments.value)) LTE arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>

	</cffunction>


	<cffunction name="exact_length" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif len(trim(arguments.value)) EQ arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>

	</cffunction>

	<!--- comparison function. Used to handle less_than,greater_than,less_than_or_equal_to,greater_than_or_equal_to 
		   and additional date compare functions --->
    <cffunction name="compare_values" output="false" returntype="boolean" access="private">
    	<cfargument name="value" type="string" required="true" />
        <cfargument name="operator" type="string" required="true" hint="comparison operator. One of: LT, LTE, GT, GTE">
        <cfargument name="argument" type="string" required="true" />
        <cfargument name="date" type="boolean" required="true" default="false" hint="type of comparison to run (true for utlizing parseDateTime()" />
       
       	<cfset var local = structNew() />
       
       	<cfset local.value = arguments.value />
		<cfset local.argument = listToArray(arguments.argument, '|') />
		<cfset local.argumentField = '' />
		
		<!--- if the first argument value passed is actually a field, use the field value instead of the field name--->
        <cfif structKeyExists(variables.rc, local.argument[1])>
			<cfset local.argumentField = local.argument[1] />
            <cfset local.argument[1] = variables.rc[local.argument[1]]  />
        </cfif>
        
		<cfif arguments.date>
        	<cfif isDate(local.value) && isDate(local.argument[1])>
				<cfif arrayLen(local.argument) GTE 2>
                    <cfset local.dateTimeMask = local.argument[2] />
                <cfelse>
                    <cfset local.dateTimeMask = 'mm/dd/yyyy h:nn TT' />
                </cfif>

            	<cfset local.value = parseDateTime(local.value) />
            	<cfset local.argument[1] = parseDateTime(local.argument[1]) />
                
				<!--- if the field exists in the request collection, update the rc field value with the mask'ed value --->
                <cfif local.argumentField NEQ ''>         
					<cfset variables.rc[local.argumentField] = dateTimeFormat(local.argument[1], local.dateTimeMask) />
                </cfif>     
            <cfelse>
            	<cfreturn false />
            </cfif>

        </cfif>
        
        <cfreturn evaluate("local.value #arguments.operator# local.argument[1]") />
    </cffunction>
    
	<cffunction name="greater_than" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'GT', arguments.argument) />
	</cffunction>
    
	<cffunction name="greater_than_datetime" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'GT', arguments.argument, TRUE) />
	</cffunction>    
    
	<cffunction name="greater_than_or_equal_to" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'GTE', arguments.argument) />

	</cffunction>    
    
	<cffunction name="greater_than_or_equal_to_datetime" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'GTE', arguments.argument, TRUE) />

	</cffunction>     

	<cffunction name="less_than" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'LT', arguments.argument) />
	</cffunction>

	<cffunction name="less_than_datetime" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'LT', arguments.argument, TRUE) />
	</cffunction>
    
	<cffunction name="less_than_or_equal_to" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'LTE', arguments.argument) />
	</cffunction>

	<cffunction name="less_than_or_equal_to_datetime" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = structNew() />
        
        <cfreturn compare_values(arguments.value, 'LTE', arguments.argument, TRUE) />
	</cffunction>

	<cffunction name="select_at_least" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif listLen(arguments.value) GTE arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="select_no_more_than" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif listLen(arguments.value) LTE arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="contains" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif arguments.value CONTAINS arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="does_not_contain" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfif arguments.value DOES NOT CONTAIN arguments.argument>
			<cfreturn true>
		</cfif>

		<cfreturn false>
	</cffunction>

	<cffunction name="valid_email" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^([a-z0-9\+_\-]+)(\.[a-z0-9\+_\-]+)*@([a-z0-9\-]+\.)+[a-z]{2,6}$", arguments.value)>

	</cffunction>

	<cffunction name="alpha" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^([a-z])+$", arguments.value)>
	</cffunction>


	<cffunction name="alpha_numeric" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^([a-z0-9])+$", arguments.value)>
	</cffunction>

	<cffunction name="alpha_dash" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^([-a-z0-9_-])+$", arguments.value)>
	</cffunction>


	<cffunction name="numeric" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^[\-+]?[0-9]*\.?[0-9]+$", arguments.value)>
	</cffunction>

	<cffunction name="integer" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^[\-+]?[0-9]+$", arguments.value)>
	</cffunction>

	<cffunction name="is_natural" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^[0-9]+$", arguments.value)>
	</cffunction>

	<cffunction name="is_natural_no_zero" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfif arguments.value EQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn REFindNoCase("^[0-9]+$", arguments.value)>

	</cffunction>

	<cffunction name="valid_base64" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfif arguments.value EQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn REFindNoCase("[^a-zA-Z0-9\/\+=]", arguments.value)>

	</cffunction>

	<cffunction name="value_is_one_of" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = {}>

		<cfloop list="#arguments.value#" index="local.value">
			<cfif NOT ListFindNoCase(arguments.argument, local.value, "|")>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>

	</cffunction>

	<cffunction name="lookup_value" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="variableName" default="">

		<cfset var local = {}>

		<!--- lookup struct doesn't exist; fail it --->
		<cfif NOT structKeyExists(variables.lookups, arguments.argument)>
			<cfreturn false>
		</cfif>

		<!--- If we are passed in an empty string, we want to allow this; if you want to only allow actual
		      characters in the list, you must set the 'required' routine for the validation rules --->
		<cfif arguments.value EQ ''>
			<cfreturn true>
		</cfif>

		<cfloop list="#arguments.value#" index="local.value">

			<cfset local.found = false>

			<cfloop from="1" to="#ArrayLen(variables.lookups[arguments.argument])#" index="local.i">
				<!--- the current list item exists in the array --->
				<cfif variables.lookups[arguments.argument][local.i].key EQ local.value>
					<cfset local.found = true>
					<!--- we found the current value, all is well; try the next list if there is one--->
					<cfbreak>
				</cfif>

			</cfloop>

			<cfif local.found EQ false>
				<cfreturn local.found>
			</cfif>

		</cfloop>

		<cfreturn local.found>
	</cffunction>

	<cffunction name="valid_url" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("https?://([-\w\.]+)+(:\d+)?(/([\w/_\.]*(\?\S+)?)?)?", arguments.value)>
	</cffunction>

	<cffunction name="valid_ip" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b", arguments.value)>
	</cffunction>

	<cffunction name="valid_ssn" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^\d{3}-\d{2}-\d{4}$", arguments.value)>
	</cffunction>

	<cffunction name="valid_postal" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^((\d{5}-\d{4})|(\d{5})|([A-Z]\d[A-Z]\s\d[A-Z]\d))$", arguments.value)>
	</cffunction>

	<cffunction name="valid_date" output="false" returntype="boolean" access="public">
    	<cfargument name="value" required="false" type="any" default="">
        
        <cfreturn isDate(arguments.value)>
    </cffunction>

	<cffunction name="valid_time" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^((0?[1-9]|1[012])(:[0-5]\d){0,2}(\ [AP]M))$|^([01]\d|2[0-3])", arguments.value) AND isDate(arguments.value)>
	</cffunction>

	<cffunction name="valid_phoneUS" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^[2-9]\d{2}-\d{3}-\d{4}$", arguments.value)>
	</cffunction>

	<cffunction name="valid_currencyUS" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">

		<cfreturn REFindNoCase("^\$?\-?([1-9]{1}[0-9]{0,2}(\,\d{3})*(\.\d{0,2})?|[1-9]{1}\d{0,}(\.\d{0,2})?|0(\.\d{0,2})?|(\.\d{1,2}))$|^\-?\$?([1-9]{1}\d{0,2}(\,\d{3})*(\.\d{0,2})?|[1-9]{1}\d{0,}(\.\d{0,2})?|0(\.\d{0,2})?|(\.\d{1,2}))$|^\(\$?([1-9]{1}\d{0,2}(\,\d{3})*(\.\d{0,2})?|[1-9]{1}\d{0,}(\.\d{0,2})?|0(\.\d{0,2})?|(\.\d{1,2}))\)$", arguments.value)>
	</cffunction>

	<cffunction name="valid_creditcard" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">

		<cfset var local = {}>

		<!--- Set the argument to the type (brand) of card passed in --->
		<cfif structKeyExists(variables.rc, arguments.argument)>
			<cfset arguments.argument = variables.rc[arguments.argument]>
		<cfelse>
			<cfset arguments.argument = ''>
		</cfif>


		<cfset local.cardNumber = "">
		<cfset local.cardType = "">
		<cfset local.processedNumber = ''>
		<cfset local.calculatedNumber = 0>
		<cfset local.i = 0>

		<!--- Take out spaces and dashes. Flip card number around for processing --->
		<cfset local.cardNumber = replace(arguments.value," ","","all")>
		<cfset local.cardNumber = replace(local.cardNumber,"-","","all")>
		<cfset local.cardNumber = reverse(local.cardNumber)>
		<cfset local.cardType = 'Unknown'>
		<cfif isNumeric(local.cardNumber) AND len(local.cardNumber) GT 12>
			<!---Double every other digit--->
			<cfloop from="1" to="#len(local.cardNumber)#" index="local.i">
				<cfif local.i MOD 2 EQ 0>
					<cfset local.processedNumber = local.processedNumber & mid(local.cardNumber,local.i,1) * 2>
				<cfelse>
					<cfset local.processedNumber = local.processedNumber & mid(local.cardNumber,local.i,1)>
				</cfif>
			</cfloop>
			<!--- Sum the processed digits --->
			<cfloop from="1" to="#len(local.processedNumber)#" index="local.i">
				<cfset local.calculatedNumber = local.calculatedNumber + val(mid(local.processedNumber,local.i,1))>
			</cfloop>

			<!--- we are a valid number --->
			<cfif local.calculatedNumber NEQ 0 and local.calulatedNumber MOD 10 EQ 0>

				<cfset local.cardNumber = reverse(local.cardNumber)>

				<cfif ((len(local.cardNumber) EQ 15) AND (((left(local.cardNumber,2) EQ "34")) OR ((left(local.cardNumber,2) EQ "37"))))>
					<cfset local.cardType = 'Amex'>
				</cfif>
				<cfif ((len(local.cardNumber) EQ 14) AND (((left(local.cardNumber,3) GTE 300) AND (left(local.cardNumber,3) LTE 305)) OR (left(local.cardNumber,2) EQ "36") OR (left(local.cardNumber, 2) EQ "38")))>
					<cfset local.cardType = 'Diners'>
				</cfif>
				<cfif ((len(local.cardNumber) EQ 16) AND (left(local.cardNumber,4) EQ "6011"))>
					<cfset local.cardType = 'Discover'>
				</cfif>
				<cfif ((len(local.cardNumber) EQ 16) AND (left(local.cardNumber,2) GTE 51) AND (left(local.cardNumber,2) LTE 55))>
					<cfset local.cardType = 'MasterCard'>
				</cfif>
				<cfif (((len(local.cardNumber) EQ 13) OR (len(local.cardNumber) EQ 16)) and (left(local.cardNumber,1) EQ "4"))>
					<cfset local.cardType = 'Visa'>
				</cfif>

				<cfif arguments.argument EQ '' OR (local.cardType EQ arguments.argument)>
					<cfreturn true>
				</cfif>

			</cfif>
		</cfif>

		<cfreturn false>

	</cffunction>

	<!--- Unsupported
	<cffunction name="valid_file" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="false" type="any" default="">
		<cfargument name="argument" required="false" type="any" default="">
		<cfargument name="field" required="false" type="any" default="">

		<cfset var oFormUtils = createObject("FormUtils")>
		<cfset var local = {}>

		<cfset loadMimeTypes()>

		<!--- Find the file in the form params --->
		<cfset local.file = oFormUtils.getFormParams()[arguments.field][1]>

		<!--- Check to see if the file extension matches those supplied in the argument --->
		<cfif listFindNoCase(arguments.argument, local.file.extension, "|") EQ 0>
			<cfreturn false>
		<!--- Check to see if the mimeType matches --->
		<cfelseif arrayFind(getMimeType(local.file.extension), local.file.type) EQ 0>
			<cfreturn false>
		</cfif>

		<cfreturn true>
	</cffunction> --->

	<cffunction name="is_empty" output="false" access="public" returntype="boolean"
				hint="Checks to see if all of the fields are empty">
		<cfargument name="value" required="true" type="string">
		<cfargument name="argument" required="true" type="string">
		<cfargument name="field" required="true" type="string">
		<cfset var local = {}>

		<cfloop list="#arguments.argument#" index="i" delimiters="|">
			<cfif len(trim(getValue(i, ""))) GT 0>
				<cfreturn true>
			</cfif>
		</cfloop>

		<cfset arguments.argument = arrayToList(listToArray(arguments.argument, "|"), ", ")>
		<cfif NOT hasErrorMessage("is_empty", arguments.field)>
			<cfset setFieldErrorMessage(arguments.field, "is_empty", "You must supply a value for one of the following fields: #arguments.argument#.")>
		</cfif>
		<cfreturn false>
	</cffunction>

	<cffunction name="between" output="false" returntype="boolean" access="public">
          <cfargument name="value" required="true" type="string">
          <cfargument name="argument" required="true" type="string">
          <cfargument name="field" required="true" type="string">

          <cfset var local = {}>

          <cfif listLen(arguments.argument, '|') EQ 2>
               <cfset local.lower = listGetAt(arguments.argument, 1, '|')>
               <cfset local.upper = listGetAt(arguments.argument, 2, '|')>
          </cfif>

          <!--- the following code replaces the [ARGUMENT] in the error message with the text
                 'lowerArg and upperArg' --->
          <cfset local.betweenMessage = local.lower & ' and ' & local.upper>

          <cfset local.message = getErrorMessage(arguments.field, 'between')>
          <cfset local.message = replaceNoCase(local.message, '[ARGUMENT]', local.betweenMessage, 'all')>

          <cfset setFieldErrorMessage(arguments.field, 'between', local.message)>
          <cfreturn len(arguments.value) GTE local.lower && len(arguments.value) LTE local.upper>
     </cffunction>

	 <cffunction name="equals" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="true" type="string">
		<cfargument name="argument" required="true" type="string">
		<cfargument name="field" required="true" type="string">

		<cfreturn arguments.value EQ arguments.argument>
	 </cffunction>

	 <cffunction name="valid_pdf" output="false" returntype="boolean" access="public">
	 	<cfargument name="value" required="true" type="string">
		<cfargument name="argument" required="true" type="string">
		<cfargument name="field" required="true" type="string">

		<cfif NOT hasErrorMessage("valid_pdf", arguments.field)>
			<cfset setFieldErrorMessage(arguments.field, "valid_pdf", "The [LABEL] field does not contain a valid PDF file")>
		</cfif>

		<cftry>
			<cfpdf action="read" name="local.pdf" source="#arguments.value#">
			<cfreturn true>
			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
	 </cffunction>

	<cffunction name="max_decimal" output="false" returntype="boolean" access="public">
		<cfargument name="value" required="true" type="string">
		<cfargument name="argument" required="true" type="string">
		<cfargument name="field" required="true" type="string">

		<cfset var pp = {}>

		<!--- Parses the arguments, eg. [6|2] for decimal length of 6 and 2 decimal places --->
		<cfif listLen(arguments.argument, '|') EQ 2>
			<cfset pp.precision = listGetAt(arguments.argument, 1, '|')>
			<cfset pp.scale = listGetAt(arguments.argument, 2, '|')>
		</cfif>

		<cftry>
			<!--- Bails if the decimal places exceeds the amount set --->
			<cfif len(val(listrest(arguments.value, "."))) gt pp.scale>
				<cfif not haserrormessage("max_decimal", arguments.field)>
					<cfset setFieldErrorMessage(arguments.field, "max_decimal", "The [LABEL] field is restricted to #pp.scale# decimal points.")>
					<cfreturn false>
				</cfif>
			</cfif>

			<!--- Bails if the total length of the value exceeds the amount set --->
			<cfif not haserrormessage("max_decimal", arguments.field)>
				<cfset setFieldErrorMessage(arguments.field, "max_decimal", "The [LABEL] field length exceeds the allowed maximum threshold.")>
			</cfif>
			<cfreturn len(numberformat(arguments.value, ".#repeatstring("9", pp.scale)#")) lte (pp.precision+1)>

			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cffunction>
 
	<cffunction name="valid_email_list" returntype="boolean" output="false" access="public">
		<cfargument name="value" type="string" required="true" />
		<cfargument name="argument" type="string" required="true" />
		<cfargument name="field" type="string" required="true" />

		<cfloop list="#arguments.value#" index="i">
			<cfif NOT isValid("email", i)>
				<cfif NOT hasErrorMessage("valid_email_list", arguments.field)>
					<cfset setFieldErrorMessage(arguments.field, "valid_email_list", "The [LABEL] field does not contain a valid list of email addresses")>
				</cfif>
				<cfreturn false>
			</cfif>
		</cfloop>

		<cfreturn true>
	</cffunction>

	<cffunction name="loadMimeTypes" returntype="void" access="public" output="false">

		<!--- Microsoft Office Formats (Office 2003 and Prior) --->
		<cfset variables.mimeTypes.doc  = 'application/msword,application/vnd.ms-word'>
		<cfset variables.mimeTypes.mdb  = 'application/vnd.ms-access,application/vnd.ms-access'>
		<cfset variables.mimeTypes.mpp  = 'application/msproject,application/vnd.ms-project'>
		<cfset variables.mimeTypes.one  = 'application/msonenote,vnd.ms-onenote'>
		<cfset variables.mimeTypes.ppt  = 'application/mspowerpoint,application/vnd.ms-powerpoint'>
		<cfset variables.mimeTypes.pub  = 'application/mspublisher,vnd.ms-publisher'>
		<cfset variables.mimeTypes.xsl  = 'application/msexcel,application/vnd.ms-excel'>

		<!--- Microsoft Office Formats (Office 2007)--->
		<cfset variables.mimeTypes.docx = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'>
		<cfset variables.mimeTypes.pptx = 'pptx,application/vnd.openxmlformats-officedocument.presentationml.presentation'>
		<cfset variables.mimeTypes.xlsx = 'xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'>

		<!--- Other Document Formats--->
		<cfset variables.mimeTypes.csv  = 'text/csv,text/comma-seperated-values'>
		<cfset variables.mimeTypes.htm  = 'text/html'>
		<cfset variables.mimeTypes.html = variables.mimeTypes.htm>
		<cfset variables.mimeTypes.pdf  = 'application/pdf'>
		<cfset variables.mimeTypes.rtf  = 'application/rtf,text/rtf'>
		<cfset variables.mimeTypes.txt  = 'text/plain'>
		<cfset variables.mimeTypes.xml  = 'text/xml'>

		<!--- Image Formats--->
		<cfset variables.mimeTypes.bmp  = 'image/bmp'>
		<cfset variables.mimeTypes.gif  = 'image/gif'>
		<cfset variables.mimeTypes.jpg  = 'image/jpeg'>
		<cfset variables.mimeTypes.jpeg = variables.mimeTypes.jpg>
		<cfset variables.mimeTypes.png  = 'image/png,image/x-png'>
		<cfset variables.mimeTypes.tif  = 'image/tiff'>
		<cfset variables.mimeTypes.tiff = variables.mimeTypes.tif>

		<!--- Vector Image Formats--->
		<cfset variables.mimeTypes.ai   = 'application/postscript'>
		<cfset variables.mimeTypes.swf  = 'application/x-shockwave-flash'>
		<cfset variables.mimeTypes.svg  = 'image/svg+xml'>

		<!--- Video Formats--->
		<cfset variables.mimeTypes.avi  = 'video/x-msvideo'>
		<cfset variables.mimeTypes.mov  = 'video/quicktime'>
		<cfset variables.mimeTypes.mpg  = 'video/mpeg'>
		<cfset variables.mimeTypes.wmv  = 'video/x-ms-wmv'>

		<!--- Audio Formats--->
		<cfset variables.mimeTypes.au   = 'audio/basic'>
		<cfset variables.mimeTypes.mid  = 'audio/midi'>
		<cfset variables.mimeTypes.mp3  = 'audio/mpeg'>
		<cfset variables.mimeTypes.ogg  = 'application/ogg'>
		<cfset variables.mimeTypes.wav  = 'audio/x-wav'>

		<!--- Other Formats--->
		<cfset variables.mimeTypes.zip  = 'application/zip,application/x-zip'>

	</cffunction>

	<cffunction name="dump" output="true" access="public" returntype="void">
		<cfdump var="#variables#">
	</cffunction>

</cfcomponent>
