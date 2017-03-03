function BS = viqualitymodis(VIQdec)
% BS = viqualitymodis(VIQdec)
% 
% INPUTS
%   VIQdec   : The decimal value of the VI Quality variable extracted from
%              MODIS data at a specific pixel (e.g. MOD13Q1.006).
% 
% OUTPUTS
%   BS       : Bit string coming from conversion of the VIQdec provided as
%              input. Each bit string is attached with a human-readable
%              string to help user inderstand the quality of the VI value
%              at current pixel.
% 
% DESCRIPTION
%   This function converts the VI Quality decimal value in strings
%   containing useful information about the pixel.
%   A by-product is the generation of a 16-bit binary value (bit-word or
%   bit-string) to which the specific labels are attached according to the
%   codification reported in:
%       https://lpdaac.usgs.gov/sites/default/files/public/modis/docs/MODIS_LP_QA_Tutorial-2.pdf

%% PRE
BS{1,1} = 'VI Quality';
BS{2,1} = 'VI usefulness';
BS{3,1} = 'Aerosol quantity';
BS{4,1} = 'Adjacent cloud detected';
BS{5,1} = 'Atmospheric BRDF Correction';
BS{6,1} = 'Mixed clouds';
BS{7,1} = 'Land‐Water Mask ';
BS{8,1} = 'Possible snow/ice';
BS{9,1} = 'Possible cloud shadow';
%% main
quality     = de2bi(VIQdec,16,'left-msb');
q           = num2str(quality);
q(q==' ')   = '';% e.g. 0000100001000100

% Now "read" the code:
% e.g.              0 | 0 | 001 | 0 | 0 | 0 | 01 | 0001 | 00

% BS = bit string   9 | 8 |   7 | 6 | 5 | 4 |  3 |    2 |  1

% VI Quality
switch q(15:16)
    case '00'
        BS{1,2} = 'VI produced with good quality';
        BS{1,3} = '00';
    case '01'
        BS{1,2} = 'VI produced, but check other QA';
        BS{1,3} = '01';
    case '10'
        BS{1,2} = 'Pixel produced, but most probably cloudy';
        BS{1,3} = '10';
    case '11'
        BS{1,2} = 'Pixel not produced due to other reasons than clouds';
        BS{1,3} = '11';
end

% VI usefulness
switch q(11:14)
    case '0000'
        BS{2,2} = 'Highest quality';
        BS{2,3} = '0000';
    case '0001'
        BS{2,2} = 'Lower quality';
        BS{2,3} = '0001';
    case '0010'
        BS{2,2} = 'Decreasing quality';
        BS{2,3} = '0010';
    case '0100'
        BS{2,2} = 'Decreasing quality';
        BS{2,3} = '0100';
    case '1000'
        BS{2,2} = 'Decreasing quality';
        BS{2,3} = '1000';
    case '1001'
        BS{2,2} = 'Decreasing quality';
        BS{2,3} = '1001';
    case '1010'
        BS{2,2} = 'Decreasing quality';
        BS{2,3} = '1010';
    case '1100'
        BS{2,2} = 'Lowest quality';
        BS{2,3} = '1100';
    case '1101'
        BS{2,2} = 'Quality so low that it is not useful';
        BS{2,3} = '1101';
    case '1110'
        BS{2,2} = 'L1B data faulty';
        BS{2,3} = '1110';
    case '1111'
        BS{2,2} = 'Not useful for any other reason/not processed';
        BS{2,3} = '1111';
    otherwise% UNDOCUMENTED
        BS{2,2} = 'UNDOCUMENTED (Decreasing quality?)';
        BS{2,3} = q(11:14);
end

% Aerosol Quantity
switch q(9:10)
    case '00'
        BS{3,2} = 'Climatology';
        BS{3,3} = '00';
    case '01'
        BS{3,2} = 'Low';
        BS{3,3} = '01';
    case '10'
        BS{3,2} = 'Intermediate';
        BS{3,3} = '10';
    case '11'
        BS{3,2} = 'High';
        BS{3,3} = '11';
end

% Adjacent Cloud detected
switch q(8)
    case '0'
        BS{4,2} = 'No';
        BS{4,3} = '0';
    case '1'
        BS{4,2} = 'Yes';
        BS{4,3} = '1';
end

% Atmospheric BRDF Correction
switch q(7)
    case '0'
        BS{5,2} = 'No';
        BS{5,3} = '0';
    case '1'
        BS{5,2} = 'Yes';
        BS{5,3} = '1';
end

% Mixed Clouds
switch q(6)
    case '0'
        BS{6,2} = 'No';
        BS{6,3} = '0';
    case '1'
        BS{6,2} = 'Yes';
        BS{6,3} = '1';
end

% Land-Water Mask
switch q(3:5)
    case '000'
        BS{7,2} = 'Shallow ocean';
        BS{7,3} = '000';
    case '001'
        BS{7,2} = 'Land (Nothing else but land)';
        BS{7,3} = '001';
    case '010'
        BS{7,2} = 'Ocean coastlines and lake shorelines';
        BS{7,3} = '010';
    case '011'
        BS{7,2} = 'Shallow inland water';
        BS{7,3} = '011';
    case '100'
        BS{7,2} = 'Ephemeral water';
        BS{7,3} = '100';
    case '101'
        BS{7,2} = 'Ocean coastlines and lake shorelines';
        BS{7,3} = '101';
    case '110'
        BS{7,2} = 'Moderate or continental ocean';
        BS{7,3} = '110';
    case '111'
        BS{7,2} = 'Deep ocean';
        BS{7,3} = '111';
end

% Possible Snow/Ice
switch q(2)
    case '0'
        BS{8,2} = 'No';
        BS{8,3} = '0';
    case '1'
        BS{8,2} = 'Yes';
        BS{8,3} = '1';
end

% Possible Shadow
switch q(1)
    case '0'
        BS{9,2} = 'No';
        BS{9,3} = '0';
    case '1'
        BS{9,2} = 'Yes';
        BS{9,3} = '1';
end
%% return
end