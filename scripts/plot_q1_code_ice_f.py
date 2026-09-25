"""Regenerate Q1 paper figures from Code_ICE_F MATLAB output."""
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import Normalize
from scipy.io import loadmat

ROOT = Path(__file__).resolve().parents[1]
DATA = loadmat(ROOT / "data" / "q1_code_ice_f.mat", simplify_cells=True)
OUT = ROOT / "figures"
mpl.rcParams.update({
    "font.family": ["Times New Roman", "SimSun"],
    "font.size": 8,
    "axes.titlesize": 8,
    "axes.labelsize": 8,
    "xtick.labelsize": 8,
    "ytick.labelsize": 8,
    "mathtext.fontset": "stix",
    "axes.unicode_minus": False,
    "pdf.fonttype": 42,
})


def tidy(ax):
    ax.grid(True, color="#d9d9d9", lw=0.5)
    ax.tick_params(direction="in", top=True, right=True, width=0.6, length=2.5)
    for spine in ax.spines.values():
        spine.set_linewidth(0.6)


def fade_band(ax, x0, x1, color, peak=0.25):
    # One RGBA image with a continuous left-to-right alpha gradient.
    rgba = np.empty((2, 1024, 4), dtype=float)
    rgba[..., :3] = mpl.colors.to_rgb(color)
    rgba[..., 3] = peak * np.linspace(1.0, 0.0, rgba.shape[1])
    ax.imshow(rgba, extent=(x0, x1, *ax.get_ylim()), origin="lower",
              interpolation="bilinear", aspect="auto", zorder=0,
              rasterized=True)


def arrow(ax, start, end, color="#c45543"):
    ax.annotate("", xy=end, xytext=start,
                arrowprops=dict(arrowstyle="-|>", mutation_scale=10,
                                color=color, lw=1.2), zorder=6)


purple = "#74439a"
purple_light = "#ab73be"
for name, temperature in (("q20", -20), ("q25", -25)):
    q = DATA[name]
    fig, axs = plt.subplots(2, 2, figsize=(14 / 2.54, 9.1 / 2.54))
    fig.subplots_adjust(left=0.085, right=0.985, bottom=0.105, top=0.935,
                        wspace=0.27, hspace=0.38)
    a, b, c, d = axs.flat
    for ax in axs.flat:
        ax.set_xlim(0, 40)
        ax.set_xticks([0, 10, 20, 30, 40])
        tidy(ax)
        ax.set_xlabel("时间 / s")

    # (a) Current: same stage bands, dashed boundaries, and red callouts.
    a.set(title="(a) 加载电流密度", ylabel="电流密度 / (A·cm⁻²)", ylim=(0, 0.305))
    fade_band(a, 6, 13.2, "#ed985e")
    fade_band(a, 24, 28, "#ed985e")
    for xline in (6, 24):
        a.axvline(xline, color="black", lw=0.75, ls="--", zorder=3)
    a.plot(q["t"], q["currentDensityAcm2"], color=purple, lw=1.35, zorder=4)
    a.text(17, 0.047, "电流上升段", ha="center", va="center", weight="bold")
    arrow(a, (14.4, 0.075), (11.8, 0.125))
    arrow(a, (20.4, 0.075), (23.1, 0.125))

    # (b) Voltage: continuous experiment as the original dashed trace.
    b.set(title="(b) 单电池电压", ylabel="单电池电压 / V", ylim=(0, 0.9))
    fade_band(b, 6, 13.2, "#ed985e")
    fade_band(b, 13.2, 30, "#a7c76d", 0.28)
    for xline in (6, 13.2):
        b.axvline(xline, color="black", lw=0.75, ls="--", zorder=3)
    b.plot(q["t"], q["Vcell"], color=purple, lw=1.35, label="模型值", zorder=4)
    b.plot(q["expTime"], q["expVoltage"], color=purple_light, lw=1.2,
           ls=(0, (5, 3)), label="实验值", zorder=5)
    b.text(10.0, 0.16, "电压\n急落", ha="center", va="center", weight="bold")
    arrow(b, (10.0, 0.28), (10.0, 0.49))
    b.text(28.0, 0.34, "电压缓升", ha="center", va="center", weight="bold")
    arrow(b, (24.0, 0.46), (21.7, 0.58), "#83a745")
    b.legend(loc="lower right", frameon=True, fancybox=False,
             edgecolor="black", framealpha=1, fontsize=7)

    # (c) Temperature: model and experiment keep the former two line styles.
    ylow = -20.0 if temperature == -20 else -25.0
    yhigh = -12.0 if temperature == -20 else -16.0
    c.set(title="(c) 平均温度", ylabel="平均温度 / °C", ylim=(ylow, yhigh))
    c.plot(q["t"], q["TavgC"], color=purple, lw=1.35,
           label="模型值", zorder=4)
    c.plot(q["expTime"], q["expTemperatureC"], color=purple_light,
           lw=1.2, ls=(0, (5, 3)), label="实验值", zorder=5)
    ytext = -17.5 if temperature == -20 else -21.5
    c.text(12, ytext, "温升曲线\n紧密贴合", ha="center", va="center", weight="bold")
    curve_point = (22.0, float(np.interp(22.0, q["t"], q["TavgC"])))
    arrow(c, (17.0, ytext+0.2), curve_point)
    c.legend(loc="lower right", frameon=True, fancybox=False,
             edgecolor="black", framealpha=1, fontsize=7)

    # (d) Ice: retain the former onset marker but use F-version onset.
    ice = q["ice"].max(axis=1)
    onset = float(q["t"][np.flatnonzero(ice > 1e-8)[0]])
    ymax = 0.020 if temperature == -20 else 0.055
    d.set(title="(d) 最大冰体积分数", ylabel="最大冰体积分数", ylim=(0, ymax))
    d.axvline(onset, color="black", lw=0.75, ls="--", zorder=3)
    fade_band(d, onset, 36.6, "#ed985e")
    d.plot(q["t"], ice, color=purple, lw=1.35, zorder=4)
    d.text(22.0, ymax*0.28, "开始产冰", ha="center", va="center", weight="bold")
    arrow(d, (18.5, ymax*0.22), (onset+0.9, ymax*0.055))

    fig.savefig(OUT / f"p1_f_verify_T{abs(temperature)}.pdf", dpi=400)
    plt.close(fig)

fig, axs = plt.subplots(2, 2, figsize=(14 / 2.54, 9 / 2.54), layout="constrained")
for ax, (field, title) in zip(axs.flat, (
    ("Erev", "可逆电压 Erev"),
    ("etaAct", "活化损失 etaAct"),
    ("etaOhm", "欧姆损失 etaOhm"),
    ("etaCon", "浓差损失 etaCon"),
)):
    for name, label, color in (("q20", "-20 °C", "#265c9c"), ("q25", "-25 °C", "#dc6a3b")):
        q = DATA[name]
        ax.plot(q["t"], q[field], label=label, lw=1.2, color=color)
    ax.set(xlabel="时间 / s", ylabel="电压 / V", title=title, xlim=(0, 36.6))
    ax.legend(frameon=False, fontsize=7)
    tidy(ax)
fig.savefig(OUT / "p1_f_loss.pdf")
plt.close(fig)

fig, axs = plt.subplots(1, 3, figsize=(14 / 2.54, 5.1 / 2.54), layout="constrained")
for ax, (field, title, ylabel) in zip(axs, (
    ("lambdaMean", "PEM 平均含水量", "$\\lambda_{PEM}$"),
    ("lambdaCCL", "cCL 离聚物含水量", "$\\lambda_{cCL}$"),
    ("iceAreaFactor", "冰覆盖面积因子", "$f_{ice}$"),
)):
    for name, label, color in (("q20", "-20 °C", "#265c9c"), ("q25", "-25 °C", "#dc6a3b")):
        q = DATA[name]
        ax.plot(q["t"], q[field], label=label, lw=1.2, color=color)
    ax.set(xlabel="时间 / s", ylabel=ylabel, title=title, xlim=(0, 36.6))
    ax.legend(frameon=False, fontsize=7)
    tidy(ax)
fig.savefig(OUT / "p1_f_hydration.pdf")
plt.close(fig)

# Keep the established two-panel, shared-scale, time-coloured Q1 ice design.
target_times = np.linspace(10, 35, 251)
norm = Normalize(vmin=10, vmax=35, clip=True)
cmap = mpl.colormaps["turbo"]
vmax = max(float(np.max(DATA[name]["ice"][DATA[name]["t"] <= 35]))
           for name in ("q20", "q25"))
fig = plt.figure(figsize=(14 / 2.54, 5.2 / 2.54))
grid = fig.add_gridspec(1, 3, width_ratios=[1, 1, 0.055],
                        left=0.10, right=0.87, bottom=0.22, top=0.88, wspace=0.24)
axs = [fig.add_subplot(grid[0, 0])]
axs.append(fig.add_subplot(grid[0, 1], sharex=axs[0], sharey=axs[0]))
cax = fig.add_subplot(grid[0, 2])
for ax, name, title in zip(axs, ("q20", "q25"), ("-20 °C 工况", "-25 °C 工况")):
    q = DATA[name]
    x = np.arange(1, q["ice"].shape[1] + 1)
    profiles = np.column_stack([np.interp(target_times, q["t"], q["ice"][:, j])
                                for j in range(q["ice"].shape[1])])
    for low, high, t0, t1 in zip(profiles[:-1], profiles[1:], target_times[:-1], target_times[1:]):
        ax.fill_between(x, np.minimum(low, high), np.maximum(low, high),
                        where=np.maximum(low, high) > np.minimum(low, high) + 1e-12,
                        color=cmap(norm((t0+t1)/2)), linewidth=0,
                        edgecolor="none", antialiased=False, interpolate=True, rasterized=True)
    ax.axvline(38.5, color="black", lw=0.85, ls=(0, (3, 2)), zorder=12)
    ax.set(title=title, xlabel="多孔介质网格单元编号", xlim=(19.5, 44.5),
           ylim=(0, 1.06*vmax), xticks=[20,25,30,35,40,44])
    ax.yaxis.set_major_locator(mpl.ticker.MaxNLocator(nbins=5, min_n_ticks=4))
    ax.yaxis.set_major_formatter(mpl.ticker.FormatStrFormatter("%.3f"))
    tidy(ax)
    transform = ax.get_xaxis_transform()
    for label, xl, xr in (("cCL", 20, 38.5), ("cGDL", 38.5, 44)):
        ax.annotate("", xy=(xl+0.15,0.76), xytext=(xr-0.15,0.76),
                    xycoords=transform, textcoords=transform, zorder=14,
                    arrowprops=dict(arrowstyle="<->", color="#222222", lw=0.65,
                                    shrinkA=0, shrinkB=0))
        ax.text((xl+xr)/2, 0.84, label, transform=transform, ha="center",
                va="center", fontsize=8, zorder=13,
                bbox=dict(facecolor="white", edgecolor="none", alpha=0.78, pad=0.8))
axs[0].set_ylabel("冰体积分数")
axs[1].tick_params(labelleft=False)
cb = fig.colorbar(mpl.cm.ScalarMappable(norm=norm, cmap=cmap), cax=cax)
cb.ax.set_xlabel("$t/\\mathrm{s}$", labelpad=3)
cb.set_ticks([10,15,20,25,30,35])
cb.outline.set_linewidth(0.6)
fig.savefig(OUT / "p1_f_ice_profiles_timecolor.pdf", dpi=400)
plt.close(fig)
