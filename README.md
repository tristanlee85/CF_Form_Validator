CF_Form_Validator
=================

Validate forms dynamically and quickly within a Cold Fusion environment. 

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
