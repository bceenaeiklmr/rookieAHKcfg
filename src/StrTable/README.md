# StrTable

StrTable is a powerful and highly configurable ASCII table generator for AutoHotkey v2, and now it's available in Python. It allows you to format tabular data from strings, text files, clipboard contents with customizable headers, borders, alignments, and padding.

The Python version is my [CS50 Python](https://cs50.harvard.edu/python)'s [Final Project](https://www.youtube.com/watch?v=yaZsFX0vZUE).

## Features
+ Supports string (CSV-like), text files, array, and clipboard input
+ Customizable headers, borders, separators, padding, and alignment
+ Display indexes
+ Auto-detects delimiters in CSV-style input
+ Title case, Upper case, Lower case, Reverse case, Random case string formatting options
+ Adjustable padding and float precision
+ Option to remove borders

## Installation

To install the required dependencies for this project, run:

Python
```bash
pip install -r requirements.txt
```

## From string
AutoHotkey
```ahk
#include StrTable.ahk
s := "Name,Age,Rank`nTony Soprano,47,Boss`nCristopher Moltisanti,30,Capo`nDuck Debugger,4.2,Consigliere"
table := StrTable(s)
A_Clipboard := table.convert()
```
Python
```python
s = "Name,Age,Rank\nTony Soprano,47,Boss\nCristopher Moltisanti,30,Capo\nDuck Debugger,4.2,Consigliere"
table = StrTable(s)
print(str(table))
```
Output:
```
+--------------------------------------------------+
|  #   |         NAME          | AGE |    RANK     |
+--------------------------------------------------+
|  0   |     Tony Soprano      | 47  |    Boss     |
|  1   | Cristopher Moltisanti | 30  |    Capo     |
|  2   |     Duck Debugger     | 4.2 | Consigliere |
+--------------------------------------------------+
```
Changing the properties
```python
table.show_index = True             # Add and display the index column
table.header_format = "random"      # Format the header to uppercase
table.line_format = "lower"         # Format the cells to lowercase
table.header_alignment = "center"   # Align the header to the center
table.line_alignment = "center"     # Align the cells to the left
table.separator = "|"               # Change the separator
table.header = ["π", "-"]           # Change the header line
table.bottom = ["Ω", "."]           # Change the bottom line
table.padding = 2                   # Change the padding
s = table.convert()                 # Convert the table to a string
```
Output:
```ahk
π----------------------------------------------------------π
|   #    |          NAme           |  age  |     RANk      |
π----------------------------------------------------------π
|   0    |      tony soprano       |  47   |     boss      |
|   1    |  cristopher moltisanti  |  30   |     capo      |
|   2    |      duck debugger      |  4.2  |  consigliere  |
Ω..........................................................Ω
```
## From array (ahk)
```ahk
a := [["A", "B", "C"], [4, "ahk v2", 6.2], [7, 8.567, 9], [true, 11, "42"]]
a := StrTable(a1)
a.header_format := "Titlecase"
a.header_alignment := "Left"
a.header := ["X", "-", "x", "."]
A_Clipboard := a1.convert()
```
Output:
```
X---x--------x-------x
| A | B      | C     |
x...x........x.......x
| 4 | ahk v2 | 6.200 |
| 7 | 8.567  | 9     |
| 1 | 11     | 42    |
+---+--------+-------+
```
## From string changing the properties
```ahk
; From string changing the padding, alignment and removing the border
s2 := "Name,Age,Rank`nTony Soprano,47,Boss`nCristopher Moltisanti,30,Capo"
s2 := StrTable(s2, False)
s2.padding := 1
s2.remove_border()
s2.line_alignment := "Right"
Outputdebug(s2.convert(limit := 2))
```
Output:
```
         Name           Age  Rank
          Tony Soprano   47  Boss
 Cristopher Moltisanti   30  Capo
```
