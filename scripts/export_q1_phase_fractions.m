% Export gas, liquid-water and ice bulk volume fractions from the calibrated
% Q1 cold-start model for the two validation temperatures.

projectDir = fileparts(fileparts(mfilename('fullpath')));
runtimeRoot = fullfile(fileparts(projectDir), 'tmp', 'code_ice_runtime');
codeDir = fullfile(runtimeRoot, 'Code_ICE');
attachmentDir = fullfile(runtimeRoot, ...
    '氢燃料电池低温冷启动建模与控制策略研究  附件');
sourceCodeDir = 'D:\数学建模\B题\Math_Modeling_2026_B\Code_ICE';
sourceAttachment = ['D:\数学建模\B题\', ...
    '氢燃料电池低温冷启动建模与控制策略研究  附件\附件2.xlsx'];

if ~isfolder(codeDir), mkdir(codeDir); end
if ~isfolder(attachmentDir), mkdir(attachmentDir); end
copyfile(fullfile(sourceCodeDir, '*.m'), codeDir, 'f');
copyfile(sourceAttachment, fullfile(attachmentDir, '附件2.xlsx'), 'f');
addpath(codeDir);

simOpt.j0Ref = 0.0827422651388;
simOpt.Ea = 7028.980902;
simOpt.fHydDry = 0.06;
simOpt.lambdaHydOn = 3.5;
simOpt.lambdaHydWet = 8.0;
simOpt.nHyd = 3.0;
simOpt.tauHyd = 10;
simOpt.hVaporCathode = 0.01;
simOpt.init.lambdaCCL0 = 1.0;
simOpt.kFreeze = 1;
simOpt.kMelt = 0;
simOpt.gammaIce = 0.1;
simOpt.tEnd = [];
simOpt.plot = false;
simOpt.verbose = false;

temperatureCases = [-20, -25];
phaseResults = cell(size(temperatureCases));

for caseIndex = 1:numel(temperatureCases)
    temperatureC = temperatureCases(caseIndex);
    [result, model] = pemfc_calculate_ice(temperatureC, simOpt);

    nTime = numel(result.t);
    nPorous = numel(model.g.idx_porous);
    gas = zeros(nTime, nPorous);
    liquid = zeros(nTime, nPorous);
    ice = zeros(nTime, nPorous);

    for timeIndex = 1:nTime
        [~, out] = model.rhs(result.t(timeIndex), result.x(timeIndex, :).');
        gas(timeIndex, :) = out.water.eps_g(model.g.idx_porous).';
        liquid(timeIndex, :) = out.water.liquidBulkVolumeFraction(:).';
        ice(timeIndex, :) = ...
            out.water.iceVolumeFraction(model.g.idx_porous).';
    end

    phaseResults{caseIndex} = struct( ...
        't', result.t(:), ...
        'gas', gas, ...
        'liquid', liquid, ...
        'ice', ice);
end

t20 = phaseResults{1}.t;
gas20 = phaseResults{1}.gas;
liquid20 = phaseResults{1}.liquid;
ice20 = phaseResults{1}.ice;
t25 = phaseResults{2}.t;
gas25 = phaseResults{2}.gas;
liquid25 = phaseResults{2}.liquid;
ice25 = phaseResults{2}.ice;

outputPath = fullfile(projectDir, 'data', 'q1_phase_fraction_data.mat');
save(outputPath, 't20', 'gas20', 'liquid20', 'ice20', ...
    't25', 'gas25', 'liquid25', 'ice25', '-v7');
fprintf('saved: %s\n', outputPath);
