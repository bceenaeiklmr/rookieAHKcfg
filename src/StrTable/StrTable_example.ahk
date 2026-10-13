; Script     StrTable_example.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/StrTable
; Date       13.10.2026
; Version    0.2.0

#include StrTable.ahk

/*
+------------------------+-----+--------------+---------------------+
|          Name          | Age |  Occupation  |      Location       |
+------------------------+-----+--------------+---------------------+
| Tony Soprano           | 47  | Crime Boss   | North Caldwell      |
| Carmela Soprano        | 45  | Housewife    | North Caldwell      |
| Christopher Moltisanti | 30  | Capo         | Newark              |
| Paulie Gualtieri       | 60  | Underboss    | Newark              |
| Silvio Dante           | 50  | Consigliere  | North Caldwell      |
| Meadow Soprano         | 20  | Student      | Columbia University |
| A.J. Soprano           | 17  | Student      | North Caldwell      |
| Dr. Jennifer Melfi     | 50  | Psychiatrist | Newark              |
| Adriana La Cerva       | 30  | Club Manager | Newark              |
| Janice Soprano         | 45  | Freelancer   | Seattle             |
+------------------------+-----+--------------+---------------------+
*/

; From string with the default settings
s1 := "name,age,occupation,location`nTony Soprano,47,Crime Boss,North Caldwell`nCarmela Soprano,45,Housewife,North Caldwell`nChristopher Moltisanti,30,Capo,Newark`nPaulie Gualtieri,60,Underboss,Newark`nSilvio Dante,50,Consigliere,North Caldwell`nMeadow Soprano,20,Student,Columbia University`nA.J. Soprano,17,Student,North Caldwell`nDr. Jennifer Melfi,50,Psychiatrist,Newark`nAdriana La Cerva,30,Club Manager,Newark`nJanice Soprano,45,Freelancer,Seattle"
s1 := StrTable(s1)
output .= s1.convert() '`r`n'

/*
+------+--------+-------+
| Col1 | Col2   | Col3  |
+------+--------+-------+
| 4    | ahk v2 | 6.200 |
| 7    | 8.567  | 9     |
| 1    | 11     | 42    |
+------+--------+-------+
*/

; From array with a custom header
a1 := [["Col1", "Col2", "Col3"], [4, "ahk v2", 6.2], [7, 8.567, 9], [true, 11, "42"]]
a1 := StrTable(a1)
a1.header_format := "Titlecase"
a1.header_alignment := "Left"
a1.header := ["X", "-", "x", "."]
output .= a1.convert() '`r`n'

/*
abc 
   1
   2
3.14
*/

; From string changing the padding, alignment and removing the border
s2 := "abc`n1`n2`n3.14`n4`n"
s2 := StrTable(s2, False)
s2.padding := 0
s2.remove_border()
s2.line_alignment := "Right"
output .= s2.convert(limit := 4) '`r`n'

/*
=========
|  Abc  |
=========
|     1 |
|     2 |
| 3.140 |
*.......*
*/

; From array with a custom header and bottom line
a2 := ["abc", 1, 2, 3.14]
a2 := StrTable(a2)
a2.header := ["=", "=", "=", "="]
a2.bottom := ["*", "."]
a2.line_alignment := "Right"
output .= a2.convert() '`r`n'

; From clipboard
;s := StrTable((A_Clipboard := A_Clipboard)) ...

A_Clipboard := output
OutputDebug(output)
