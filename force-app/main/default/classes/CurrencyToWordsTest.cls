@isTest
public class CurrencyToWordsTest {
    @isTest
    static void testConvertBelowTwenty() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 15;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertBelowHundred() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 45;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertBelowThousand() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 123;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertBelowTenThousand() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 5678;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertBelowLakh() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 45678;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertBelowMillion() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 123456;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertBelowCrore() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 12345678;
        String result = converter.getConvertedValue();
    }

    @isTest
    static void testConvertAboveCrore() {
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = 123456789;
        String result = converter.getConvertedValue();
    }
}