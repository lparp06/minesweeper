module pop_count(
 
	input [63:0]input_number,	
	output reg [5:0]out
);


always @ (*) 
	out = input_number[0] + input_number[1] + input_number[2] 
					     + input_number[3] + input_number[4] + input_number[5] 
			           + input_number[6] + input_number[7] + input_number[8] 
						  + input_number[9] + input_number[10] + input_number[11]
						  + input_number[12] + input_number[13] + input_number[14]
						  + input_number[15] + input_number[16] + input_number[17]
						  + input_number[18] + input_number[19] + input_number[20]
						  + input_number[21] + input_number[22] + input_number[23]
						  + input_number[24] + input_number[25] + input_number[26]
						  + input_number[27] + input_number[28] + input_number[29]
						  + input_number[30] + input_number[31] + input_number[32]
						  + input_number[33] + input_number[34] + input_number[35]
						  + input_number[36] + input_number[37] + input_number[38]
						  + input_number[39] + input_number[40] + input_number[35]
						  + input_number[42] + input_number[43] + input_number[44]
						  + input_number[45] + input_number[46] + input_number[47]
						  + input_number[48] + input_number[49] + input_number[50]
						  + input_number[51] + input_number[52] + input_number[53]
						  + input_number[54] + input_number[55] + input_number[56]
						  + input_number[57] + input_number[58] + input_number[59]
						  + input_number[60] + input_number[61] + input_number[62] + input_number[63];
endmodule