# Final project for CS50P - port of StrTable.ahk.
# Script     test_StrTable.py
# License:   MIT License
# Author:    Bence Markiel (bceenaeiklmr)
# Github:    https://github.com/bceenaeiklmr/StrTable
# Date       13.10.2026


# Import 
from StrTable import get_delimiter, inverse_case, StrTable
import pytest


# Raises error for wrong parameters
def test_init():

    table = StrTable("a,b,c\n1,2,3")

    assert len(table.data) == 2        # lines
    assert len(table.lengths) == 3     # columns

    return


def test_data():

    test = "Name,Age,Rank\n" \
    "Tony Soprano,47,Boss\n" \
    "Cristopher Moltisanti,30,Capo\n" \
    "Duck Debugger,4.2,Consigliere"

    table = StrTable(test)

    assert table.data[0][2] == "Rank"              # header - 3rd column
    assert table.data[3][0] == "Duck Debugger"     # 4th line - name

    return


def test_convert():

    test = "Name,Age,Rank\n"
    "Tony Soprano,47,Boss\n"
    "Cristopher Moltisanti,30,Capo\n"
    "Duck Debugger,4.2,Consigliere"

    table = StrTable(test)
    table.convert()
    assert len(table.txt) > 0

    return


# Additional functions
def test_delimiter():
    assert get_delimiter("abc,") == ","
    assert get_delimiter("abc;") == ";"
    assert get_delimiter("abc:") == ":"
    assert get_delimiter("abc\t") == "\t"
    # ValueError.
    with pytest.raises(ValueError):
        get_delimiter("abc")

    return


def test_str_case():

    # Inverse
    assert inverse_case("cs50p") == "CS50P"
    assert inverse_case("CS50P") == "cs50p"
    assert inverse_case("") == ""


def test_uneven_rows():
    test = "Col1,Col2\nA,B,C,D\n1"
    table = StrTable(test)
    assert len(table.lengths) == 4
    txt = table.convert()
    assert "D" in txt
    assert "1" in txt

