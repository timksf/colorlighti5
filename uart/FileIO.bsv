package FileIO;

import List :: *;

module mkReadLine#(Handle hdl)(String);
    
    Bool open       <- hIsOpen(hdl);
    Bool readable   <- hIsReadable(hdl);

    if(open && readable) begin
        String line <- hGetLine(hdl);
        return line;
    end else 
        return "";

endmodule

module mkReadFileStringList#(String filename)(List#(String));

    Handle hdl <- openFile(filename, ReadMode);

    List#(String) fileContents = tagged Nil;
    Bool isEOF <- hIsEOF(hdl);

    while(!isEOF) begin
        String line <- mkReadLine(hdl);
        if(stringLength(line) > 0)
            fileContents = cons(line, fileContents);
        isEOF <- hIsEOF(hdl);
    end

    hClose(hdl);

    return reverse(fileContents);
endmodule

endpackage