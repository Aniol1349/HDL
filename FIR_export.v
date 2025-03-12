% File name for the COE file
coe_filename = 'stage2_filter.coe'; 

% Open file for writing
fileID = fopen(coe_filename, 'w');

% Write the COE file header
fprintf(fileID, '; Xilinx FIR Compiler Coefficient File\n');
fprintf(fileID, '; Generated from MATLAB\n');
fprintf(fileID, 'Radix = 10;\n'); % Specify the radix (decimal)
fprintf(fileID, 'Coefficient_Width = 18;\n'); % Match coefficient width to FIR settings
fprintf(fileID, 'CoefData =\n'); % Start coefficient data section

% Write the coefficients
for i = 1:length(scaled_coefs)
    if i < length(scaled_coefs)
        fprintf(fileID, '%d,\n', scaled_coefs(i)); % Add a comma for all but the last coefficient
    else
        fprintf(fileID, '%d;\n', scaled_coefs(i)); % Final coefficient ends with a semicolon
    end
end

% Close the file
fclose(fileID);

disp(['COE file generated: ', coe_filename]);
