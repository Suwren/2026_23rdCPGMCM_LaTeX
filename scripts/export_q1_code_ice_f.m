% Recompute both Q1 validation cases with the unmodified Code_ICE_F model.
projectDir = fileparts(fileparts(mfilename('fullpath')));
runtimeRoot = fullfile(fileparts(projectDir), 'tmp', 'code_ice_f_runtime');
codeDir = fullfile(runtimeRoot, 'Code_ICE_F');
attachmentDir = fullfile(runtimeRoot, ...
    '氢燃料电池低温冷启动建模与控制策略研究  附件');
sourceCodeDir = 'D:\数学建模\B题\Math_Modeling_2026_B\Code_ICE_F';
sourceAttachment = ['D:\数学建模\B题\', ...
    '氢燃料电池低温冷启动建模与控制策略研究  附件\附件2.xlsx'];
if ~isfolder(codeDir), mkdir(codeDir); end
if ~isfolder(attachmentDir), mkdir(attachmentDir); end
copyfile(fullfile(sourceCodeDir, '*.m'), codeDir, 'f');
copyfile(sourceAttachment, fullfile(attachmentDir, '附件2.xlsx'), 'f');
addpath(codeDir);

for temperatureC = [-20, -25]
    [result, model] = pemfc_calculate_ice(temperatureC, ...
        struct('plot',false,'verbose',false));
    nTime = numel(result.t);
    nPorous = numel(model.g.idx_porous);
    ice = zeros(nTime,nPorous);
    Erev = zeros(nTime,1); etaAct = Erev; etaOhm = Erev; etaCon = Erev;
    for k = 1:nTime
        [~, out] = model.rhs(result.t(k),result.x(k,:).');
        ice(k,:) = out.water.eps_i(model.g.idx_porous).';
        Erev(k) = out.voltage.Erev;
        etaAct(k) = out.voltage.etaAct;
        etaOhm(k) = out.voltage.etaOhm;
        etaCon(k) = out.voltage.etaCon;
    end
    q = struct();
    q.t = result.t(:); q.ice = ice;
    q.Vcell = result.Vcell(:); q.TavgC = result.TavgC(:);
    q.currentDensityAcm2 = result.currentDensityAcm2(:);
    q.maxIceSaturation = result.maxIceSaturation(:);
    q.iceSaturationCCL = result.iceSaturationCCL(:);
    q.iceMassPerArea = result.iceMassPerArea(:);
    q.lambdaMean = result.lambdaMean(:);
    q.lambdaCCL = result.lambdaCCL(:);
    q.iceAreaFactor = result.iceAreaFactor(:);
    q.Erev = Erev; q.etaAct = etaAct; q.etaOhm = etaOhm;
    q.etaCon = etaCon;
    q.expTime = result.experiment.time(:);
    q.expVoltage = result.experiment.voltage(:);
    q.expTemperatureC = result.experiment.temperatureC(:);
    q.voltageRMSE = result.voltageRMSE;
    q.temperatureRMSE = result.temperatureRMSE;
    q.Tmin = result.Tmin(:); q.Tmax = result.Tmax(:);
    if temperatureC == -20, q20 = q; else, q25 = q; end
    fprintf('%d C: voltage RMSE %.6f V, temperature RMSE %.6f C, ice max %.6f\n', ...
        temperatureC,q.voltageRMSE,q.temperatureRMSE,max(ice(end,:)));
end
save(fullfile(projectDir,'data','q1_code_ice_f.mat'),'q20','q25','-v7');
