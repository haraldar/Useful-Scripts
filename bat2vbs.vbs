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


Sub vbsify(ByVal strFileName, ByVal blnRunAfter, ByVal blnDeleteAfter)
	'''
	' Wrap the specified file into VBS code, that creates a batch file, executes it
	' and deletes the produced file afterwards if opted in.
	' Params:
	'	strFileName (vbString): The file to wrap into vbs.
	'	blnRunAfter (vbBoolean): Decides if the file will run after being produced.
	'	blnDeleteAfter (vbBoolean): Decides if the file will delete itself after.
	'''
	
	Dim strFileContent, arrFileContent, strNewFileName, strTempLine, fileOut
	
	' Get the filecontent and the new filename for the output file.
	strFileContent = readFileContent(strFileName)
	strNewFileName = changeFileExtension(strFileName, "vbs")

	' Split the content into an array of lines.
	arrFileContent = Split(strFileContent, vbCrLf)

	' Create the new file and fill it with the wrapper code.
	Set fileOut = objFSO.CreateTextFile(strNewFileName, True)
	fileOut.WriteLine "Dim objWrapperFSO, objWrapperOutFile"
	fileOut.WriteLine "Set wrapperShell = WScript.CreateObject(""WScript.Shell"")"
	fileOut.WriteLine "Set objWrapperFSO = CreateObject(""Scripting.FileSystemObject"")"
	fileOut.WriteLine "Set objWrapperOutFile = objWrapperFSO.CreateTextFile(""" & strFileName & """, True)"
	For Each strLine In arrFileContent
		' double quotes need to be double double quotes
		fileOut.WriteLine "objWrapperOutFile.WriteLine """ & Replace(strLine, """", """""") & """"
	Next
	If blnRunAfter Then
		fileOut.WriteLine "Dim wrapperShell"
		fileOut.WriteLine "Set wrapperShell = WScript.CreateObject(""WScript.Shell"")"
		fileOut.WriteLine "wrapperShell.Run strNewFileName, 0, false"
	End If
	fileOut.WriteLine "objWrapperOutFile.Close"
	If blnDeleteAfter Then
		fileOut.WriteLine "If objWrapperFSO.FileExists(""" & strFileName & """) Then"
		fileOut.WriteLine "    objWrapperFSO.DeleteFile(""" & strFileName & """)"
		fileOut.WriteLine "End If"
	End If
	fileOut.Close
	
End Sub


Sub displayHelp()
	'''
	' Display the tools' description, usage and options.
	'''
	
	' Description
	WScript.Echo "This tool creates an embeddable VBS-script, that when run creates a"
	WScript.Echo "bat-file and can execute and/ or run it."
	
	' Usage
	WScript.Echo "Usage:"
	WScript.Echo "    cscript.exe .../bat2vbs.vbs [preoptions (optional)] [file target] [anteoptions]"

	' Preoptions
	WScript.Echo "Preoptions:"
	WScript.Echo "    -h:    Help."
	WScript.Echo "    -c:    Display the content of the target file."
	WScript.Echo "    -i:    (TODO) Insert the code into an existing VBS-file."
	
End Sub


Sub errExit(ByVal msg)
	WScript.Echo msg
	WScript.Quit
End Sub


Sub main()
	'''
	' The main procedure. The script arguments are evaluated in a 
	' first-come-first-serve fashion.
	'''

	Dim objArgs, intArgsAmount
	Set objArgs = WScript.Arguments
	intArgsAmount = objArgs.Count
	
	Dim strScriptDir
	strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
	
	Dim UNKNOWN_ARG : UNKNOWN_ARG = "Unknown argument."
	Dim NOT_ENOUGH_ARGS : NOT_ENOUGH_ARGS = "Not enough arguments supplied."
	Dim ARG_NOT_FILE : ARG_NOT_FILE = "Argument supplied is not an existing file."
	
	If intArgsAmount = 0 OR intArgsAmount > 2 Then
		' The script expects at least one argument.
		errExit(NOT_ENOUGH_ARGS) 
	ElseIf intArgsAmount = 1 Then
		Select Case objArgs(0)
			Case "-h"
				displayHelp()
			Case "-i"
				errExit("This feature is yet to be implemented.")
			Case Else
				If objFSO.FileExists(objArgs(0)) Then
					vbsify objArgs(0), False, False
				ElseIf objFSO.FileExists(strScriptDir & objArgs(0)) Then
					vbsify strScriptDir & objArgs(0), False, False
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
		End Select
	End If
	
	WScript.Quit
	
End Sub


main()