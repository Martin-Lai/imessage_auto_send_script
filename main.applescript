checkEnable()

set convertedPhoneNumberList to showInputNumberDialog()

set list_ans to choose from list convertedPhoneNumberList with title "確認電話號碼" with prompt "確認以下電話號碼" OK button name "確認" cancel button name "取消" default items {first string of convertedPhoneNumberList} with multiple selections allowed

if list_ans is false then
	error number -128
end if

set content to display dialog "訊息內容" default answer linefeed with icon note buttons {"Continue"} default button "Continue"
set textMessage to text returned of content

display dialog textMessage with title ("發送至" & (count of convertedPhoneNumberList) & "筆號碼") buttons {"取消", "發送"} default button "發送" cancel button "取消"

tell application "Messages"
	
	set targetService to (id of 1st account whose service type = iMessage)
	
	repeat with convertedPhoneNumber in convertedPhoneNumberList
		
		set targetBuddy to convertedPhoneNumber
		
		set theBuddy to participant targetBuddy of account id targetService
		
		send textMessage to theBuddy
		
		delay 0.1
		
	end repeat
	
end tell

delay (count of convertedPhoneNumberList) / 100 + 3

set sql_path to "~/Library/Messages/chat.db"

set sql_command to "select message.ROWID as id, " & ¬
	"case message.is_delivered when 1 then \"success\" else \"fail\" end as delivered, " & ¬
	"case message.is_sent when 1 then \"success\" else \"fail\" end as sent, " & ¬
	"handle.id as \"number\", handle.service from message " & ¬
	"join handle on handle.ROWID = message.handle_id " & ¬
	"where is_from_me = 1 and message.account_guid = \"" & targetService & "\" " & ¬
	"order by message.ROWID DESC limit " & (count of convertedPhoneNumberList)

set date_str to get_current_date_time_str()

do shell script "mkdir -p ~/Desktop/message_record"

set sql to ¬
	"sqlite3 -header -csv " & sql_path & " '" & sql_command & ";'" & ¬
	" > ~/Desktop/message_record/" & date_str & ".csv"
do shell script sql

postData(count of convertedPhoneNumberList, sql_path, sql_command, date_str)

display dialog "已完成, 統計表已輸出至桌面！！" buttons {"ok!!"}

on checkEnable()
	set check_enable_script to "curl 'https://imessage-1-68e2a-default-rtdb.asia-southeast1.firebasedatabase.app/version.json'"
	set enable to do shell script check_enable_script
	if enable is not "1" then
		display dialog "Please update to the latest version !!" buttons {"OK"}
		error number -128
	end if
end checkEnable

on showInputNumberDialog()
	set phoneNumberInput to display dialog "輸入手機號碼" default answer linefeed with icon note buttons {"Continue"} default button "Continue"
	set phoneNumbers to text returned of phoneNumberInput
	set phoneNumberList to split(phoneNumbers, "
")
	set convertedPhoneNumberList to {}
	
	repeat with p in phoneNumberList
		if (p starts with "0") then
			set convertedPhoneNumberList to convertedPhoneNumberList & (findReplace("-", "", findAndReplaceFirstOccurrenceInText(p, "0", "+886")))
		else if (p starts with "886") then
			set convertedPhoneNumberList to convertedPhoneNumberList & ("+" & p)
		else if (p starts with "+886") then
			set convertedPhoneNumberList to convertedPhoneNumberList & p
		end if
	end repeat
	
	if (count of convertedPhoneNumberList) > 3000 then
		set input_number_ans to display dialog "單次不得超過3000筆電話號碼" with icon stop buttons {"取消", "重新輸入"} default button "重新輸入"
		log input_number_ans
		return showInputNumberDialog()
	end if
	
	if (count of convertedPhoneNumberList) = 0 then
		display dialog "未輸入有效號碼" with icon stop buttons {"取消", "重新輸入"} default button "重新輸入"
		return showInputNumberDialog()
	end if
	
	return convertedPhoneNumberList
end showInputNumberDialog

on postData(select_size, sql_path, sql_command, date_str)
	set sent_fail_script to "sqlite3 ~/Library/Messages/chat.db  'select count(*) from (" & sql_command & ") where sent = \"fail\" ;'"
	set delivered_fail_script to "sqlite3 ~/Library/Messages/chat.db  'select count(*) from (" & sql_command & ") where delivered = \"fail\" ;'"
	set success_script to "sqlite3 ~/Library/Messages/chat.db  'select count(*) from (" & sql_command & ") where delivered = \"success\" and sent = \"success\" ;'"
	set all_data_script to "sqlite3 -json " & sql_path & " '" & sql_command & ";'"
	
	set sent_fail_count to do shell script sent_fail_script
	set delivered_fail_count to do shell script delivered_fail_script
	set success_count to do shell script success_script
	set all_record to do shell script all_data_script
	
	// post your data to server
end postData

to split(someText, delimiter)
	set AppleScript's text item delimiters to delimiter
	set someText to someText's text items
	set AppleScript's text item delimiters to {""}
	return someText
end split

to findAndReplaceFirstOccurrenceInText(theText, theSearchString, theReplacementString)
	set AppleScript's text item delimiters to theSearchString
	return text item 1 of theText & theReplacementString & text (text item 2) thru (text item -1) of theText
end findAndReplaceFirstOccurrenceInText

on findReplace(findText, replaceText, sourceText)
	set ASTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set sourceText to text items of sourceText
	set AppleScript's text item delimiters to replaceText
	set sourceText to "" & sourceText
	set AppleScript's text item delimiters to ASTID
	return sourceText
end findReplace

on list2string(theList, theDelimiter)
	
	set theBackup to AppleScript's text item delimiters
	
	set AppleScript's text item delimiters to theDelimiter
	
	set theString to theList as string
	
	set AppleScript's text item delimiters to theBackup
	
	return theString
	
end list2string

on get_current_date_time_str()
	set now to (current date)
	
	set result to (year of now as integer) as string
	set result to result & "-"
	set result to result & zero_pad(month of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(day of now as integer, 2)
	set result to result & "_"
	set result to result & zero_pad(hours of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(minutes of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(seconds of now as integer, 2)
	return result
end get_current_date_time_str

on zero_pad(value, string_length)
	set string_zeroes to ""
	set digits_to_pad to string_length - (length of (value as string))
	if digits_to_pad > 0 then
		repeat digits_to_pad times
			set string_zeroes to string_zeroes & "0" as string
		end repeat
	end if
	set padded_value to string_zeroes & value as string
	return padded_value
end zero_pad