# Final project for CS50P - port of StrTable.ahk.
# Script     StrTable.py
# License:   MIT License
# Author:    Bence Markiel (bceenaeiklmr)
# Github:    https://github.com/bceenaeiklmr/StrTable
# Date       13.10.2026


import ctypes
import os
import random
import re
import sys


def main():

    # Test string.
    test = "Name,Age,Rank\nTony Soprano,47,Boss\nCristopher Moltisanti,30,Capo\nDuck Debugger,4.2,Consigliere"
    #test = "test_file.csv"

    # Initialize the table.
    table = StrTable(test)

    # Add index to first column.
    table.show_index = True

    # Customize Header.
    table.header_format = "upper"
    table.header_alignment = "left"
    table.line_alignment = "center"

    # Change characters.
    table.separator = "|"
    table.header = ["+", "-"]
    table.bottom = ["+", "-"]

    # Set padding.
    table.padding = 1

    # Print the converted text.
    print(str(table))

    # Save.
    table.save("formatted.csv")

    return


# Configurable ASCII table formatter.
class StrTable:

    # Properties
    has_header = True
    header_format = "TitleCase"
    line_format = ""
    header_alignment = "left"
    line_alignment = "center"
    separator = "|"
    header = ["+", "-"]
    bottom = ["+", "-"]
    padding = 1

    # Constructor
    def __init__(self, strg, has_header=True, file_encoding="utf-16-le"):

        self.has_header = has_header
        self.file_encoding = file_encoding
        self.data = []
        self.lengths = []
        self.txt = ""

        # Initialize property values.
        self.init_prop_values()

        # Input is a string.
        if isinstance(strg, str):

            # Try to open as file.
            if os.path.exists(strg):
                with open(strg, "r") as f:
                    self.data = self.data_from_str(f.read())
            # Just use the string.
            else:
                self.data = self.data_from_str(strg)

        # Get the column lengths.
        self.lengths = self.column_lengths(self.data)

        return

  
    # Convert, return the text.
    def __str__(self):
        return self.convert()

  
    # Save the output to a file
    def save(self, file_path, file_encoding="UTF-8", overwrite=True):

        # No content.
        if not self.txt:
            return

        # Delete previous file.
        if overwrite and os.path.exists(file_path):
            os.remove(file_path)

        # Write content.
        try:
            with open(file_path, "w", encoding=file_encoding) as f:
                f.write(self.txt)

        except PermissionError:
            print("File cannot be accessed for writing.")

        return

  
    # Remove the borders completely
    def remove_border(self):
        self.header = ["", ""]
        self.bottom = ["", ""]
        self.separator = ""
        return

  
    # Reformat cell.
    def cell_format(self, keyword, txt):

        kw = keyword.lower()

        if re.match("^l(ower)?(case)?$", kw):
            return txt.lower()

        if re.match("^t(itle)?(case)?$", kw):
            return txt.title()

        if re.match("^u(pper)?(case)?$", kw):
            return txt.upper()

        if re.match("^r(andom)?(case)?$", kw):
            return random_case(txt)

        if re.match("^i(nverse)?(case)?$", kw):
            return inverse_case(txt)

        return txt

  
    # Calculate string paddings within columns.
    def calculate_padding(self, i, j):

        # Regex patterns. Note: default pattern is left.
        re_center = r"^c(ent(er|re)?)?$"
        re_right = r"^r(ight)?$"

        # Calculate padding.
        pad = self.lengths[j] - len(str(self.data[i][j]))
        left_pad = self.padding
        right_pad = self.padding

        # Adjust padding for alignment.
        if i == 1 and re.match(re_center, self.header_alignment) or re.match(re_center, self.line_alignment):
            left_pad += pad // 2
            right_pad += pad - (pad // 2)

        elif i == 1 and re.match(re_right, self.header_alignment) or re.match(re_right, self.line_alignment):
            left_pad += pad

        else:
            right_pad += pad

        return {"left": left_pad, "right": right_pad}

  
    # Convert the string to table.
    def convert(self, limit=0):

        # Allocate memory for the string (later)
        byte_chr = 2
        lines = limit if limit else len(self.data)
        bytes = (lines + 3) * len(self.add_line()) * byte_chr - 1 * byte_chr + byte_chr
        # self.mem = bytearray(bytes)
        # print(f"Allocated bytes: {len(self.mem)}")
        strg = ""

        # Open with a decorator line.
        if self.header[0] != "" and self.header[1] != "":
            strg += self.add_line(self.header[0], self.header[1])

        # Start writing the data.
        for i, line in enumerate(self.data):

            strg += self.separator
            for j, col in enumerate(line):

                padding = self.calculate_padding(i, j)

                # Left padding.
                for k in range(padding["left"]):
                    strg += " "

                # The string.
                if re.match(r"^\w+$", self.line_format):
                    strg += self.cell_format(self.line_format, self.data[i][j])
                else:
                    strg += self.data[i][j]

                # Right padding.
                for k in range(padding["right"]):
                    strg += " "

                # Separator.
                strg += self.separator

            # Newline.
            strg += "\n"

            # Reformat header.
            if self.has_header and i == 0:

                # Apply cell_format to each header cell individually.
                header_line = ""
                txt = strg

                for k, cell in enumerate(txt.split(self.separator)):

                    # Python uses zero-index.
                    k += 1

                    # Append separator.
                    if k > 1 and k < len(txt):
                        header_line += self.separator

                    # Append header line.
                    if k == 1 or k == len(txt):
                        header_line += cell
                    else:
                        header_line += self.cell_format(self.header_format, cell)

                strg = header_line

                # In case the bottom line of the header is different.
                h = self.header
                if len(h) == 4 and h[2] != "" and h[3] != "":
                    h = [h[2], h[3]]
                else:
                    h = [h[0], h[1]]

                strg += self.add_line(h[0], h[1])

            # Break on limit.
            if limit and i + (-1 if self.has_header == True else 0) == limit:
                break

        # Append the bottom line.
        if self.bottom[0] != "" and self.bottom[1] != "":
            strg += self.add_line(self.bottom[0], self.bottom[1])

        # Remove last new line.
        self.txt = strg[:-1]
        return self.txt

  
    def add_line(self, char_first="+", char="-"):
        strg = char_first
        for len_col in self.lengths:
            # Add dashes for the column width plus padding
            strg += char * (len_col + 2 * self.padding)
            # Add column separator
            strg += char_first
        # Return the line (already ends with a separator)
        return f"{strg}\n"

  
    # Return an array with the columns string lengths.
    def column_lengths(self, data):

        if not data:
            return []

        # Find maximum columns across all rows.
        max_cols = max(len(line) for line in data)

        # Pad shorter rows to match max_cols.
        for line in data:
            while len(line) < max_cols:
                line.append("")

        # Create an array.
        lengths = [0] * max_cols

        # Find the longest string in each column.
        for i, line in enumerate(data):
            for j, col in enumerate(line):

                # Round floats to avoid long decimals like 8.5670000000000002.
                if isinstance(data[i][j], float) or (isinstance(data[i][j], str) and re.fullmatch(r"^\d+\.\d+$", data[i][j])):
                    data[i][j] = str(round(float(data[i][j]), self.float_precision))

                # Update length.
                if len(str(data[i][j])) > lengths[j]:
                    lengths[j] = len(str(data[i][j]))

        return lengths

  
    # Convert a character separater format to a multi-dimensional array.
    def data_from_str(self, strg):

        # Replace CRLF with LF, delete empty lines.
        strg = strg.replace("\r\n", "\n")
        strg = strg.replace("\n\n", "\n")

        # Remove trailing newline (e.g.: Excel copy).
        if strg[-1:] == "\n":
            strg = strg[:-1]

        # Get delimiter char.
        delim = get_delimiter(strg)

        # Split to a multi-dimensional array.
        data = []

        for line in strg.split("\n"):
            if delim:
                data.append(line.split(delim))
            else:
                data.append([line])
        return data

  
    # Will be implemented later.
    def read_mem(self):
        # txt = self.mem.decode(self.file_encoding).rstrip("\x00")
        return

  
    # Will be implemented later.
    def write_mem(self, txt):
        # self.mem[:len(txt)] = txt.encode(self.file_encoding)
        return

  
    # Not implemented yet.
    def data_from_array(self):
        return

  
    # Initialize property default values.
    def init_prop_values(self):
        self.__float_precision = 6
        self.__show_index = False
        self.__to_clipboard = False
        return

  
    # getter-setter copy content to Clipboard.
    @property
    def to_clipboard(self):
        return self.__to_clipboard

    @to_clipboard.setter
    def to_clipboard(self, value):
        if not isinstance(value, bool):
            raise ValueError
        if value and self.txt:
            copy_to_clipboard(self.txt)
            self.__to_clipboard = value
        return

  
    # getter-setter float precision.
    @property
    def float_precision(self):
        return self.__float_precision

    @float_precision.setter
    def float_precision(self, precision=2):
        if precision < 0 or precision > 16:
            raise ValueError
        self.__float_precision = precision
        return

  
    # getter-setter show index.
    @property
    def show_index(self):
        return self.__show_index

    @show_index.setter
    def show_index(self, value=True):
        if not isinstance(value, bool):
            raise ValueError

        if value == True:
            if self.show_index:
                return
            offset = 0
            for i, row in enumerate(self.data):
                if self.has_header and i == 0:
                    row.insert(0, "#")
                    offset = 1
                    continue
                row.insert(0, str(i - offset))
            # Recalculate index column width based on inserted strings.
            index_width = max(len(row[0]) for row in self.data)
            self.lengths.insert(0, index_width)
            self.__show_index = True
        else:
            if self.show_index == False:
                return
            for row in self.data:
                row.pop(0)
            # Remove the index width from the lengths.
            self.lengths.pop(0)
            self.__show_index = False
        return


# Find the delimiter character in a string.
def get_delimiter(string):
    delimiter = ",;:\t"
    for v in delimiter:
        if v in string:
            return v
    raise ValueError


# Convert a string to inverse case.
def inverse_case(string):
    s = ""
    for v in string:
        if v.isalpha() and v.isupper():
            s += v.lower()
        elif v.isalpha():
            s += v.upper()
        else:
            s += v
    return s


# Convert a string to random case.
def random_case(string):
    s = ""
    for v in string:
        if bool(random.getrandbits(1)):
            s += v.upper()
        else:
            s += v.lower()
    return s


# Copy a string to clipboard (win32)
def copy_to_clipboard(text):

    if not str(sys.platform) == "win32":
        print("Only Windows is supported.")
        return

    GMEM_MOVEABLE = 0x2000  # Allows memory to be moved
    CF_TEXT = 1  # ANSI text

    # Open, empty, alloc memory for text.
    ctypes.windll.user32.OpenClipboard(0)
    ctypes.windll.user32.EmptyClipboard()
    h_clip_mem = ctypes.windll.kernel32.GlobalAlloc(GMEM_MOVEABLE, len(text) + 1)

    # Lock the allocated memory, so it is writeable.
    ctypes.windll.kernel32.GlobalLock(h_clip_mem)
    # Copy with msvcrt strcpy.
    ctypes.cdll.msvcrt.strcpy(ctypes.windll.kernel32.GlobalLock(h_clip_mem), text.encode('utf-8'))
    # Unlock.
    ctypes.windll.kernel32.GlobalUnlock(h_clip_mem)

    # Set the clipboard data, close clipboard.
    ctypes.windll.user32.SetClipboardData(CF_TEXT, h_clip_mem)
    ctypes.windll.user32.CloseClipboard()
    return


if __name__ == "__main__":
    main()
