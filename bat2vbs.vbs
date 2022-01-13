' Wrap a batch file into a vbs script as runnable application.

' AUTHOR: HARALD ASMUS
' v0 - 13-01-2022 - reads a batch file
' v0.1 - 14-01-2022

' TODO
'	1. Comply with naming conventions.
'	2. Allow to insert the code into an existing vbs-file.

' Naming conventions used:
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
	for each strLine in arrFileContent
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


Sub main()
	Dim strFileIn, strFileOut
	strFileIn = WScript.Arguments(0)
	' TODO check the arguments here and how to process them
	' wShell.Popup strFileIn, , "BAT2VBS", 1
	' WScript.Echo readBatch(strFileIn)
	' WScript.Echo changeFileExtension(strFileIn, "vbs")
	vbsify strFileIn, False, False
	'convert2vbs()
	WScript.Quit
End Sub


main()