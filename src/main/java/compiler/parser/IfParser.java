package compiler.parser;

import compiler.block.Block;
import compiler.block.ifs.IfBlock;
import compiler.tokenizer.Token;
import compiler.tokenizer.TokenData;
import compiler.tokenizer.TokenType;
import compiler.tokenizer.Tokenizer;

/*
need to make parameter single variable names instead as cant define a variable in an ifs...
 */


public class IfParser extends Parser<IfBlock> {
    @Override
    public boolean shouldParse(String line) {
        return line.matches("if \\((.*)*\\):");
    }

    @Override
    public IfBlock parse(Block superBlock, Tokenizer tokenizer) {

        tokenizer.nextToken();  //skip if
        tokenizer.nextToken();  // skip (
        Token first = tokenizer.nextToken();
        Token operator = tokenizer.nextToken();

        System.out.println(first);
        System.out.println(operator);

        if (operator.getToken().equals(")")) {
            System.out.println("Trueefs");
            return new IfBlock(superBlock, first.getToken());
        } else {
            System.out.println("other trueee");
            Token value = tokenizer.nextToken();
            return new IfBlock(superBlock, first.getToken() + " " + operator.getToken() + " " + value.getToken());
        }
    }
}
