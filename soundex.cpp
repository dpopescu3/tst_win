/*
 * TODO: remove and replace this file header comment
 * This is a .cpp file you will edit and turn in.
 * Remove starter comments and add your own
 * comments on each function and on complex code sections.
 */
#include <cctype>
#include <fstream>
#include <string>
#include "console.h"
#include "strlib.h"
#include "filelib.h"
#include "simpio.h"
#include "vector.h"
#include "SimpleTest.h" // IWYU pragma: keep (needed to quiet spurious warning)
using namespace std;

/* This function is intended to return a string which
 * includes only the letter characters from the original
 * (all non-letter characters are excluded)
 *
 * WARNING: The provided code is buggy!
 *
 * Use test cases to identify which inputs to this function
 * are incorrectly handled. Then, remove this comment and
 * replace it with a description of the bug you fixed.
 */
string lettersOnly(string s) {
    string result = "";
    for (int i = 0; i < s.length(); i++) {
        if (isalpha(s[i])) {
            result += s[i];
        }
    }
    return result;
}


/* TODO: Replace this comment with a descriptive function
 * header comment.
 */

/* TODO: Replace this comment with a descriptive function
 * header comment.
 */
char soundexDigit(char c) {
    switch (toupper(c)) {
    case 'B': case 'F': case 'P': case 'V':
        return '1';
    case 'C': case 'G': case 'J': case 'K': case 'Q': case 'S': case 'X': case 'Z':
        return '2';
    case 'D': case 'T':
        return '3';
    case 'L':
        return '4';
    case 'M': case 'N':
        return '5';
    case 'R':
        return '6';
    default:
        return '0';
    }
}

string soundex(string s) {
    s = lettersOnly(s);
    if (s.empty()) return "0000";
    string soundexRes = "";
    soundexRes += toUpperCase(s[0]);
    char prevDigit = soundexDigit(s[0]);
    for (int i = 1; i < s.length(); i++) {
        char digit = soundexDigit(s[i]);
        if (digit != '0' && digit != prevDigit) {
            soundexRes += digit;
        }
        prevDigit = digit;
        if (soundexRes.length() == 4) break;
    }
    while (soundexRes.length() < 4) {
        soundexRes += '0';
    }
    return soundexRes;
}


/* TODO: Replace this comment with a descriptive function
 * header comment.
 */
void soundexSearch(string filepath) {
    // This provided code opens the specified file
    // and reads the lines into a vector of strings
    ifstream in;
    Vector<string> allNames;

    if (openFile(in, filepath)) {
        allNames = stringSplit(readEntire(in), '\n');
    }
    cout << "Read file " << filepath << ", "
         << allNames.size() << " names found." << endl;

    // The names read from file are now stored in Vector allNames

    /* TODO: Fill in the remainder of this function. */
}


/* * * * * * Test Cases * * * * * */


PROVIDED_TEST("Test exclude of punctuation, digits, and spaces") {
    string s = "'O'Hara";
    string result = lettersOnly(s);
    EXPECT_EQUAL(result, "OHara");
    s = "Planet9";
    result = lettersOnly(s);
    EXPECT_EQUAL(result, "Planet");
    s = "tl dr";
    result = lettersOnly(s);
    EXPECT_EQUAL(result, "tldr");
    s = "90988s";
    result = lettersOnly(s);
    EXPECT_EQUAL(result, "s");
    EXPECT_EQUAL(result, "s");
    EXPECT_EQUAL(result, "s");


}


PROVIDED_TEST("Sample inputs from handout") {
    EXPECT_EQUAL(soundex("Curie"), "C600");
    EXPECT_EQUAL(soundex("O'Conner"), "O256");
}

PROVIDED_TEST("hanrahan is in lowercase") {
    EXPECT_EQUAL(soundex("hanrahan"), "H565");
}

PROVIDED_TEST("DRELL is in uppercase") {
    EXPECT_EQUAL(soundex("DRELL"), "D640");
}

PROVIDED_TEST("Liu has to be padded with zeros") {
    EXPECT_EQUAL(soundex("Liu"), "L000");
}

PROVIDED_TEST("Tessier-Lavigne has a hyphen") {
    EXPECT_EQUAL(soundex("Tessier-Lavigne"), "T264");
}

PROVIDED_TEST("Au consists of only vowels") {
    EXPECT_EQUAL(soundex("Au"), "A000");
    EXPECT_EQUAL(soundex("Au"), "A000");

}

PROVIDED_TEST("Egilsdottir is long and starts with a vowel") {
    EXPECT_EQUAL(soundex("Egilsdottir"), "E242");
}



PROVIDED_TEST("Schwarz begins with a pair of duplicate codes") {
    EXPECT_EQUAL(soundex("Schwarz"), "S620");
}

PROVIDED_TEST("Van Niekerk has a space between repeated n's") {
    EXPECT_EQUAL(soundex("Van Niekerk"), "V526");
}

PROVIDED_TEST("Wharton begins with Wh") {

    EXPECT_EQUAL(soundex("Wharton"), "W635");

     EXPECT_EQUAL(soundex("Wharton"), "W635");


}

PROVIDED_TEST("Ashcraft is not a special case") {
    // Some versions of Soundex make special case for consecutive codes split by hw
    // We do not make this special case, just treat same as codes split by vowel
    EXPECT_EQUAL(soundex("Ashcraft"), "A226");
}

// TODO: add your test cases here


