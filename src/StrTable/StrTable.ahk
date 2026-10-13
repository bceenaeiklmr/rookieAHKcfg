; Script     StrTable.ahk
; License:   MIT License
; Author:    Bence Markiel (bceenaeiklmr)
; Github:    https://github.com/bceenaeiklmr/StrTable
; Date       13.10.2026
; Version    0.4.0

#Requires AutoHotkey v2.0
#Warn

/**
 * @class StrTable - Create an ASCII table from a string, text file, or an array
 * @param {String|Array|File} str - The input string, array, or text file
 * @param {Bool} has_header - Whether the input has a header
 * @param {String} file_encoding - The encoding of the file      
 * @example
 * text := "Name,Age,Rank`nTony Soprano,47,Boss`nCristopher Moltisanti,30,Capo"
 * table := StrTable(text)              ; Create a table from the string
 * table.show_index := True             ; Add and display the index column
 * table.header_format := "Uppercase"   ; Format the header to uppercase
 * table.line_format := "lower"         ; Format the cells to lowercase
 * table.header_alignment := "center"   ; Align the header to the center
 * table.line_alignment := "left"       ; Align the cells to the left
 * table.separator := "|"               ; Change the separator
 * table.header := ["x", "-", "y", " "] ; Change the header line
 * table.bottom := ["o", "."]           ; Change the bottom line
 * table.padding := 2                   ; Change the padding
 * table.to_clipboard := 1              ; Assign the output to the clipboard automatically
 * table.convert()                      ; Convert the table to a string
 * ;A_Clipboard := table.convert()      ; Convert the table to a string and assign to clipboard
 * OutputDebug(A_Clipboard)
 * @example
 * fileName := A_Desktop "\test.txt"    ; From file
 * table := StrTable(fileName)          ; ...
 * @example
 * arr := [["A", "B", "C"], [1337, "ahk v2", 42.123456], [true, 11, "42"]]
 * table := StrTable(arr)               ; ...
 */
class StrTable {

    ; Properties
    has_header := True
    header_format := "Titlecase"
    line_format := ""
    header_alignment := "center"
    line_alignment := "left"
    separator := "|"
    header := ["+", "-"]
    bottom := ["+", "-"]
    padding := 1

    ; Changing the float precision requires recalculating the lengths
    float_precision {
        get => this.__float_precision
        set {
            if (value < 0 || value > 16)
                return
            this.lengths := this.column_lengths()
            this.__float_precision := value
        }
    }
    
    ; Insert a new column to display the index, or remove it
    show_index {
        get => this.__show_index
        set {
            if (value == 1) {
                if (this.show_index)
                    return
                offset := 0
                loop this.data.Length {
                    if (this.has_header && A_Index == 1) {
                        this.data[A_Index].InsertAt(1, "#")
                        offset := 1
                        continue
                    }
                    this.data[A_Index].InsertAt(1, A_Index - offset)
                }
                this.lengths.InsertAt(1, StrLen(this.data.Length))
                this.__show_index := True
            }
            else if (value == 0) {
                if (this.show_index == 0)
                    return
                loop this.data.Length {
                    this.data[A_Index].RemoveAt(1)
                }
                this.lengths.RemoveAt(1)
                this.__show_index := False
            }
        }
    }

    ; Copy content to clipboard
    to_clipboard {
        get => this.__to_clipboard
        set {
            if (value < 0 || value > 1) {
                return
            }
            else if (value != this.__to_clipboard) {
                this.__to_clipboard := value
            }
            return
        }
    }
    
    ; Add a line with the specified characters
    add_line(char_first := "+", char := "-") {
        str := char_first
        loop this.lengths.Length {
            loop this.lengths[A_Index] + 2 * this.padding {
                str .= char
            }    
            str .= char_first
        }
        return str .= "`n"
    }

    ; Reformat the cell using keywords
    cell_format(keyword, str) {
        switch {
            case (keyword ~= "i)^l(ower)?(case)?$"): str := Format("{:L}", str)
            case (keyword ~= "i)^T(itle)?(case)?$"): str := Format("{:T}", str)
            case (keyword ~= "i)^U(PPER)?(case)?$"): str := Format("{:U}", str)
            case (keyword ~= "i)^r(andom)?(case)?$"): str := random_case(str)
            case (keyword ~= "i)^i(nverse)?(case)?$"): str := inverse_case(str)
        }
        return str
    }

    ; Calculate padding for a cell
    calculate_padding(i, j) {
       
        ; Regex keywords for alignment
        regex_center := "i)^c(ent(er|re)?)?$"
        regex_right := "i)^r(ight)?$"
        
        ; Calculate padding
        pad := this.lengths[j] - StrLen(this.data[i][j])
        left_pad := this.padding
        right_pad := this.padding
        
        ; Adjust padding for alignment
        if ((i == 1 && this.header_alignment ~= regex_center)
         || (this.line_alignment ~= regex_center)) {
            left_pad += pad // 2
            right_pad += pad - (pad // 2)
        }
        else if ((i == 1 && this.header_alignment ~= regex_right)
         || (this.line_alignment ~= regex_right)) {
            left_pad += pad
        }
        else {
            right_pad += pad
        }
        return { left : left_pad, right : right_pad }
    }

    ; Convert the data to a string
    convert(limit := 0) {

        ; Allocate memory for the string
        lines := (!limit) ? this.data.Length : limit
        bytes := (lines + 3) * StrLen(this.add_line()) * 2 - 1 * 2
        VarSetStrCapacity(&str, bytes)
        
        ; Open with a decorator line
        if (this.header[1] != "" && this.header[2] != "") {
            str .= this.add_line(this.header[1], this.header[2])
        }

        loop this.data.length {
            i := A_Index
            str .= this.separator
            loop this.lengths.length {
                j := A_Index   
                padding := this.calculate_padding(i, j)
                ; Left padding
                loop padding.left {
                    str .= " "
                }
                ; The string
                if (this.line_format ~= "^\w+$") {
                    str .= this.cell_format(this.line_format, this.data[i][j])
                }    
                else {
                    str .= this.data[i][j]
                }
                ; Right padding
                loop padding.right {
                    str .= " "
                }
                ; Separator
                str .= this.separator
            }
            ; Newline
            str .= "`n"
            
            ; Reformat header
            if (this.has_header && i == 1) {
                ; Apply cell_format to each header cell individually
                header_line := ""
                for k, cell in StrSplit(str, this.separator) {
                    if (k > 1 && k < StrLen(str)) {
                        header_line .= this.separator
                    }
                    if (k == 1 || k == StrLen(str)) {
                        header_line .= cell
                    } else {
                        header_line .= this.cell_format(this.header_format, cell)
                    }
                }
                str := header_line
                ; In case the bottom line of the header is different
                h := this.header
                if (h.Has(3) && h.Has(4) && h[3] != "" && h[4] != "") {
                    h := [h[3], h[4]]
                }
                else {
                    h := [h[1], h[2]]
                }
                str .= this.add_line(h[1], h[2])
            }

            ; Break on limit
            if (limit && i + (this.has_header ? -1 : 0) = limit)
                break
        }
        
        ; Append the bottom line
        if (this.bottom[1] != "" && this.bottom[2] != "") {
            str .= this.add_line(this.bottom[1], this.bottom[2])
        }
        this.str := SubStr(str, 1, -1)
        if (this.to_clipboard) {
            A_Clipboard := str
        }
        return str
    }

    ; Save the output to a file
    save(file_path, file_encoding := "UTF-8", overwrite := True) {
        if (!this.str) {
            return
        }
        if (overwrite && FileExist(file_path)) {
            FileDelete(file_path)
        }
        FileAppend(this.str, file_path, file_encoding)
        return
    }

    ; Remove the borders completely
    remove_border() {
        this.header := ["", ""]
        this.bottom := ["", ""]
        this.separator := ""
        return
    }

    ; Convert a string to a multi-dimensional array
    data_from_str(str) {
        
        ; Replace CRLF with LF, delete empty lines
        str := StrReplace(str, "`r`n", "`n")
        str := StrReplace(str, "`n`n", "`n")
        ; Remove trailing newline (e.g.: Excel copy)
        if (SubStr(str, -1) == "`n") {
            str := SubStr(str, 1, -1) 
        }              

        ; Split to a multi-dimensional array
        data := StrSplit(str, "`n")
        delim := get_delimiter(str)
        for v in data {
            data[A_Index] := (delim) ? StrSplit(v, delim) : [v]
        }
        return data
    }

    ; Validate and convert a single-dimensional array to a multi-d. array
    data_from_arr(str) {
        single_column := True
        for row in str {
            try for cell in row {
                if !(Type(cell) ~= "String|Integer|Float") {
                    throw TypeError("Not supported data type: " Type(cell))
                }
                single_column := False
            }
        }
        if (single_column) {
            arr := []
            for row in str {
                if !(Type(row) ~= "String|Integer|Float") {
                    throw TypeError("Not supported data type: " Type(row))
                }
                arr.Push([row])
            }
            return arr
        }
        return str
    }

    ; Return the length of the columns in an array
    column_lengths() {

        data := this.data
        if (data.Length == 0)
            return []

        ; Determine maximum column count across all rows
        maxCols := 0
        for row in data {
            if (row.Length > maxCols)
                maxCols := row.Length
        }

        ; Normalize/pad any shorter rows so all rows have maxCols elements
        for row in data {
            while (row.Length < maxCols)
                row.Push("")
        }

        ; Initialize lengths array for maxCols columns
        lengths := []
        lengths.Length := maxCols
        loop maxCols {
            lengths[A_Index] := 0
        }

        ; Find the longest string in each column
        loop data.Length {
            i := A_Index
            loop data[i].Length {
                j := A_Index
                ; Round floats to avoid long decimals like 8.5670000000000002
                if (Type(data[i][j]) == "Float" || data[i][j] ~= "^\d+\.\d+$") {
                    data[i][j] := Round(data[i][j], this.float_precision)
                }
                if (StrLen(data[i][j]) > lengths[j]) {
                    lengths[j] := StrLen(data[i][j])
                }
            }
        }
        return lengths
    }

    ; Init default property values
    init_prop_values() {
        this.__float_precision := 6
        this.__show_index := False
        this.__to_clipboard := False
    }

    ; Constructor
    __New(str, has_header := True, file_encoding := "UTF-8") {
        this.init_prop_values()
        this.has_header := has_header
        this.str := ""
        if (Type(str) == "String") {
            if (FileExist(str)) {
                str := FileRead(str, file_encoding)
            }
            this.data := this.data_from_str(str)
        }
        else if (Type(str) == "Array") {
            this.data := this.data_from_arr(str)
        }
        this.lengths := this.column_lengths()
        return
    }
}

; Find the delimiter in a string
get_delimiter(str) {
    delimiter := ",;:`t"
    loop parse, str {
        if (InStr(delimiter, A_LoopField)) {
            return A_LoopField
        }
    }
}

; Convert a string to random case
random_case(str) {
    s := ""
    loop parse, str {
        s .= Format('{:' (Random(0, 1) ? 'U':'L') '}', A_LoopField)
    }
    return s
}

; Convert a string to an inverse case
inverse_case(str) {
    s := ""
    loop parse, str {
        f := A_LoopField
        s .= (f == StrUpper(f) ? StrLower(f) : StrUpper(f))
    }
    return s
}
