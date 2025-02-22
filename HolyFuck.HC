#define TAPE_SIZE 30000
#define STACK_SIZE 1000

class BFInterpreter {
    I64 *tape;
    I64 dataPtr;
    I64 *bracket_stack;
    I64 stack_ptr;
    U8 *code;
    I64 code_ptr;
    I64 code_len;
};

U0 BFInterpreterInit(BFInterpreter *bf) {
    bf->tape = MAlloc(TAPE_SIZE * sizeof(I64));
    bf->bracket_stack = MAlloc(STACK_SIZE * sizeof(I64));
    MemSet(bf->tape, 0, TAPE_SIZE * sizeof(I64));
    bf->dataPtr = 0;
    bf->stack_ptr = 0;
    bf->code_ptr = 0;
}

U0 BFInterpreterCleanup(BFInterpreter *bf) {
    Free(bf->tape);
    Free(bf->bracket_stack);
}

Bool BFBracketCheck(U8 *code, I64 len) {
    I64 balance = 0;
	I64 i;
    for (i = 0; i < len; i++) {
        if (code[i] == '[') balance++;
        else if (code[i] == ']') balance--;
        if (balance < 0) return FALSE;
    }
    return balance == 0;
}

U0 BFInterpreterRun(BFInterpreter *bf)
{
    while (bf->code_ptr < bf->code_len && bf->code_ptr >= 0) {
        switch (bf->code[bf->code_ptr]) {
            case '>':
                if (bf->dataPtr < TAPE_SIZE - 1)
                    bf->dataPtr++;
                else
                    bf->dataPtr = 0;
                break;
            
            case '<':
                if (bf->dataPtr > 0)
                    bf->dataPtr--;
                else
                    bf->dataPtr = TAPE_SIZE - 1;
                break;
            
            case '+':
                bf->tape[bf->dataPtr] = (bf->tape[bf->dataPtr] + 1) & 0xFF;
                break;
            
            case '-':
                bf->tape[bf->dataPtr] = (bf->tape[bf->dataPtr] - 1) & 0xFF;
                break;
            
            case '.':
                "%c", bf->tape[bf->dataPtr] & 0xFF;
                break;
            
            case ',': {
                I64 c = GetChar;
                if (c != -1)
                    bf->tape[bf->dataPtr] = c & 0xFF;
                else
                    bf->tape[bf->dataPtr] = 0;
                break;
            }
            
            case '[': {
                if ((bf->tape[bf->dataPtr] & 0xFF) == 0) {
                    I64 count = 1;
                    while (count > 0) {
                        bf->code_ptr++;
                        if (bf->code_ptr >= bf->code_len) break;
                        if (bf->code[bf->code_ptr] == '[') count++;
                        if (bf->code[bf->code_ptr] == ']') count--;
                    }
                } else {
                    if (bf->stack_ptr < STACK_SIZE)
                        bf->bracket_stack[bf->stack_ptr++] = bf->code_ptr;
                }
                break;
            }
            
            case ']': {
                if (bf->stack_ptr > 0 && (bf->tape[bf->dataPtr] & 0xFF) != 0)
                    bf->code_ptr = bf->bracket_stack[bf->stack_ptr-1];
                else if (bf->stack_ptr > 0)
                    bf->stack_ptr--;
                break;
            }
        }
        bf->code_ptr++;
    }
}

U0 Main() {
    BFInterpreter bf;
    "=== Brainfuck Interpreter ===\n"
    "Enter program: ";
    
    U8 *prog = GetStr(, TRUE);
    
    if (prog && StrLen(prog)) {
        U8 *filtered = MAlloc(StrLen(prog)+1);
        I64 j = 0, i, k;
        U8 *valid_chars = "+-><.,[]";
        
        for (i = 0; prog[i]; i++) {
            Bool is_valid = FALSE;
            for (k=0; valid_chars[k]; k++) {
                if (prog[i] == valid_chars[k]) {
                    is_valid = TRUE;
                    break;
                }
            }
            if (is_valid)
                filtered[j++] = prog[i];
        }
        filtered[j] = 0;
        
        if (BFBracketCheck(filtered, j)) {
            bf.code = filtered;
            bf.code_len = j;
            
            BFInterpreterInit(&bf);
            BFInterpreterRun(&bf);
            BFInterpreterCleanup(&bf);
        } else {
            "\nERROR: Unbalanced brackets!\n";
        }
        Free(filtered);
    }
    Free(prog);
    "\n";
}

Main;