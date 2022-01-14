' Wrap a batch file into a vbs script as runnable application.

' AUTHOR: HARALD ASMUS
' DATE OF CREATION: 13-01-2021

' Naming conventions used (I really didn't like the docstrings there):
' http://www.sourceformat.com/coding-standard-vbs-convention.htm
' https://stackoverflow.com/questions/3281355/get-the-type-of-a-variable-in-vbscript

' Usage: cscript.exe .../bat2vbs.vbs <args>

Dim objFSO, wShell, objEnv
Set wShell = WScript.CreateObject("WScript.Shell")
Set objEnv = wShell.Environment("Process")
Set objFSO = CreateObject("Scripting.FileSystemObject")


Function readFileContent(ByVal strFileLocation)
	'''
	' Read file content.
	' Params:
	'	strFileLocation (vbString): The location of the file to read.
	' Returns:
	'	vbString: Contains the content of the 
	'''
	
	Dim objFileText, strFileContent
	
	Set objFileText = objFSO.OpenTextFile(strFileLocation, 1)
	strFileContent = objFileText.ReadAll
	objFileText.Close
	readFileContent = strFileContent
	
End Function


Function changeFileExtension(ByVal strFileLocation, ByVal strNewExtension)
	'''
	' Convert the old filename to a filename with a custom extension.
	' Params: 
	'	strFileLocation (vbString): The old file name.
	' Returns:
	'	vbString: The new filename with the replacement extension.
	'''
	
	Dim arrOldFileName
	
	'Split by the dot.
	arrOldFileName = Split(strFileLocation, ".")
	
	'Check array size, should be 2, else error and quit.
	If UBound(arrOldFileName) <> 1 Then
		WScript.Echo "More than one '.' detected in " & strFileLocation & ". Aborting."
		WScript.Quit
	End If
	
	'Replace the .bat with the new extension and combine array.
	changeFileExtension = arrOldFileName(0) & "." & strNewExtension
	
End Function


Sub displayHelp()
	'''
	' Display the tools' description, usage and options.
	'''
	
	' Description
	WScript.Echo "This tool creates an embeddable VBS-script, that when run creates a"
	WScript.Echo "bat-file and can execute and/ or run it."
	
	WScript.Echo ""

	' Usage
	WScript.Echo "Usage:"
	WScript.Echo "    cscript.exe .../bat2vbs.vbs [preoptions (optional)] [file target] [anteoptions]"

	WScript.Echo ""

	' Preoptions
	WScript.Echo "Preoptions:"
	WScript.Echo "    -h:                             Help."
	WScript.Echo "    -c <src_file>:                  Display the content of the target file."
	WScript.Echo "    -i <src_file> <target_file>:    Display the content of the target file." 
	WScript.Echo "                                    Requires a ""'VBSIFY HERE"" insertion mark somewhere in the target_file."
	WScript.Echo "                                    Should work just fine, but better have a backup."

	WScript.Echo ""
	
	' Anteoptions
	WScript.Echo "Anteoptions (all default True, and only if no preoptions):"
	WScript.Echo "    -r:    Disable piece of code to the script that will run the final bat file."
	WScript.Echo "    -d:    DIsable piece of code to the script that will delete the final bat file."
	
End Sub


Function checkFile(ByVal path)
	'''
	' Check if given path is a file and try adding the scripts parent folder. If it is
	' not a valid file, return an empty string.
	' Params:
	'	path (vbString): The path to the file.
	' Returns:
	'	vbString: The actual path.
	'''
	
	Dim strScriptDir
	strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
	' Try the path that has been passed.
	If objFSO.FileExists(path) Then
		checkFile = path
	' Try the path with this scipts' parent folder.
	ElseIf objFSO.FileExists(strScriptDir & path) Then
		checkFile = strScriptDir & path
	' If the options above didn't work, it is not a file.
	Else
		checkFile = ""
	End If
	
End Function


Sub errExit(ByVal msg)
	'''
	' Echo a message and leave.
	' Params:
	'	msg (vbString): The message to leave.
	'''
	
	WScript.Echo msg
	WScript.Quit
End Sub


Function wrapIntoVBS(ByVal strText, ByVal strFileName, ByVal blnRunAfter, ByVal blnDeleteAfter)
	'''
	' Wrap the Code into VBS.
	' Params:
	'	strText (vbString): The text that will be wrapped.
	'	strFileName (vbString): The filename of the eventually produced file.
	'	blnRunAfter (vbBoolean): Decides if the file will run after being produced.
	'	blnDeleteAfter (vbBoolean): Decides if the file will delete itself after.
	' Returns:
	'	vbString: The wrapped code text.
	'''
	
	Dim strWrapperText : strWrapperText = "Dim objWrapperFSO, objWrapperOutFile" & vbCrLf
	strWrapperText = strWrapperText & "Dim strWrapperNewFileName : strWrapperNewFileName = """ & strFileName & """" & vbCrLf
	strWrapperText = strWrapperText & "Set objWrapperFSO = CreateObject(""Scripting.FileSystemObject"")" & vbCrLf
	strWrapperText = strWrapperText & "Set objWrapperOutFile = objWrapperFSO.CreateTextFile(strWrapperNewFileName, True)" & vbCrLf
	
	Dim arrTextToWrap : arrTextToWrap = Split(strText, vbCrLf)
	For Each strLine In arrTextToWrap
		' double quotes need to be double double quotes
		strWrapperText = strWrapperText & "objWrapperOutFile.WriteLine """ & Replace(strLine, """", """""") & """" & vbCrLf
	Next
	
	If blnRunAfter Then
		strWrapperText = strWrapperText & "Dim wrapperShell" & vbCrLf
		strWrapperText = strWrapperText & "Set wrapperShell = WScript.CreateObject(""WScript.Shell"")" & vbCrLf
		strWrapperText = strWrapperText & "wrapperShell.Run strNewFileName, 0, false" & vbCrLf
	End If
	strWrapperText = strWrapperText & "objWrapperOutFile.Close" & vbCrLf
	If blnDeleteAfter Then
		strWrapperText = strWrapperText & "If objWrapperFSO.FileExists(strWrapperNewFileName) Then" & vbCrLf
		strWrapperText = strWrapperText & "    objWrapperFSO.DeleteFile(strWrapperNewFileName)" & vbCrLf
		strWrapperText = strWrapperText & "End If" & vbCrLf
	End If
	
	wrapIntoVBS = strWrapperText

End Function


Function insertIntoVBS(ByVal strSourceFile, ByVal strTargetFile, ByVal strInsertionMark)
	'''
	' Returns the string that contains the old text with the embedded vbs-code.
	' Params:
	'	strSourceFile (vbString): The file we need to convert.
	'	strTargetFile (vbString): The file where we insert into.
	'	strInsertionMark (vbString): The mark where we insert after.
	' Returns:
	'	vbString: The text with the embedded code.
	'''
	
	Dim strSourceContent, strTargetContent, arrTargetContent
	Dim strFileFromContent, strFileIntoContent, arrFileIntoContent
	
	' Read the file strSourceFile.
	strSourceContent = readFileContent(strSourceFile)
	
	' Read the file strTargetFile and split at the specified mark.
	strTargetContent = readFileContent(strTargetFile)
	arrTargetContent = Split(strTargetContent, "'" & strInsertionMark)
	
	' Check if there are duplicates of the insertion mark.
	If UBound(arrTargetContent) > 1 Then
		errExit("There are multiple insertion marks found.")
	ElseIf UBound(arrTargetContent) = 0 Then
		errExit("No insertion mark found.")
	End If
	
	' Combine the wrapped content with the original content.
	Dim strWrapperText
	strWrapperText = arrTargetContent(0) & vbCrLf
	strWrapperText = strWrapperText & wrapIntoVBS(strSourceContent, strSourceFile, True, True) & vbCrLf
	strWrapperText = strWrapperText & arrTargetContent(1)
	
	insertIntoVBS = strWrapperText
	
End Function


Sub vbsify(ByVal strFileName, ByVal blnRunAfter, ByVal blnDeleteAfter, ByVal strInsertInto, ByVal strInsertionMark)
	'''
	' Wrap the specified file into VBS code, that creates a batch file, executes it
	' and deletes the produced file afterwards if opted in.
	' Params:
	'	strFileName (vbString): The file to wrap into vbs.
	'	blnRunAfter (vbBoolean): Decides if the file will run after being produced.
	'	blnDeleteAfter (vbBoolean): Decides if the file will delete itself after.
	'''
	
	Dim strFileContent, strNewFileName, fileOut
	Dim arrWrapperText, strWrapperText
	
	If StrComp(strInsertInto, "") <> 0 Then
		strWrapperText = insertIntoVBS(strFileName, strInsertInto, strInsertionMark)
		arrWrapperText = Split(strWrapperText, vbCrLf)
	Else
		' Get the filecontent and the new filename for the output file.
		strFileContent = readFileContent(strFileName)
		
		' Create the wrapped text from the file.
		strWrapperText = wrapIntoVBS(strFileContent, strFileName, blnRunAfter, blnDeleteAfter)
		arrWrapperText = Split(strWrapperText, vbCrLf)
	End If

	' Create the new file and fill it with the wrapper code.
	strNewFileName = changeFileExtension(strFileName, "vbs")
	Set fileOut = objFSO.CreateTextFile(strNewFileName, True)
	For Each strLine In arrWrapperText
		fileOut.WriteLine strLine
	Next
	fileOut.Close
	
End Sub


Sub main()
	'''
	' The main procedure. The script arguments are evaluated in a 
	' first-come-first-serve fashion.
	'''

	Dim objArgs, intArgsAmount
	Set objArgs = WScript.Arguments
	intArgsAmount = objArgs.Count
	
	Dim strFileCheck
	Dim blnRunnable, blnDeletable
	
	Dim UNKNOWN_ARG : UNKNOWN_ARG = "Unknown argument."
	Dim NOT_ENOUGH_ARGS : NOT_ENOUGH_ARGS = "Not enough arguments supplied."
	Dim ARG_NOT_FILE : ARG_NOT_FILE = "Argument supplied is not an existing file."
	Dim INCORRECT_ARGS : INCORRECT_ARGS = "Incorrect amount of arguments supplied."
	
	If intArgsAmount = 1 Then
	
		Select Case objArgs(0)
			Case "-h"
				displayHelp()
			Case Else
			
				strFileCheck = checkFile(objArgs(0))
				If StrComp(strFileCheck, "") <> 0 Then
					vbsify strFileCheck, True, True, "", ""
				ElseIf StrComp(objArgs(0), "-c") = 0 Then
					errExit(NOT_ENOUGH_ARGS)
				Else
					errExit(UNKNOWN_ARG)
				End If
				
		End Select
		
	ElseIf intArgsAmount = 2 Then
	
		Select Case objArgs(0)
			Case "-c"
			
				If objFSO.FileExists(objArgs(1)) Then
					WScript.Echo readFileContent(objArgs(1))
				Else
					errExit(ARG_NOT_FILE)
				End If
				
			Case Else
			
				strFileCheck = checkFile(objArgs(0))
				If StrComp(strFileCheck, "") <> 0 Then
					If StrComp(objArgs(1), "-r") = 0 Then
						vbsify strFileCheck, False, True, "", ""
					ElseIf StrComp(objArgs(1), "-d") = 0 Then
						vbsify strFileCheck, True, False, "", ""
					Else
						errExit("Argument after file not recognized.")
					End If
				End If
				
		End Select
		
	ElseIf intArgsAmount = 3 Then
		strFileCheck = checkFile(objArgs(0))
		If StrComp(objArgs(0), "-i") = 0 Then
		
			Dim strFileFrom : strFileFrom = checkFile(objArgs(1))
			Dim strFileInto : strFileInto = checkFile(objArgs(2))
			If StrComp(strFileFrom, "") <> 0 AND StrComp(strFileInto, "") <> 0 Then
				vbsify strFileFrom, True, True, strFileInto, "VBSIFY HERE"
			Else
				errExit("One or more of the two necessary filepaths after -i are not files.")
			End If
			
		ElseIf StrComp(strFileCheck, "") <> 0 Then
		
			If StrComp(objArgs(1), "-r") = 0 OR StrComp(objArgs(1), "-d") = 0 Then
			
				If StrComp(objArgs(2), "-r") = 0 OR StrComp(objArgs(2), "-d") = 0 Then
					vbsify strFileCheck, False, False, "", ""
				Else
					errExit("Last argument should be anteoption.")
				End If
				
			Else
				errExit("Argument after file should be anteoption.")
			End If
			
		Else
			errExit("First argument not recognized.")
		End If
	Else
		' The script expects at least one argument.
		errExit(NOT_ENOUGH_ARGS) 
	End If
	
	WScript.Quit
	
End Sub


main()